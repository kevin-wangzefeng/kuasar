/*
Copyright 2025 The Kuasar Authors.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

use std::{collections::HashMap, sync::Arc};

use async_trait::async_trait;
use containerd_sandbox::{
    data::{ContainerData, SandboxData},
    error::{Error, Result},
    signal::ExitSignal,
    Container, ContainerOption, Sandbox, SandboxOption, SandboxStatus, Sandboxer,
};
use log::{debug, info};
use serde::{Deserialize, Serialize};
use time::OffsetDateTime;
use tokio::sync::{Mutex, RwLock};

/// ResourceSlot sandboxer - a fake sandbox that only records resource configuration
/// without actually allocating system resources
#[derive(Default)]
pub struct ResourceSlotSandboxer {
    #[allow(clippy::type_complexity)]
    pub(crate) sandboxes: Arc<RwLock<HashMap<String, Arc<Mutex<ResourceSlotSandbox>>>>>,
}

/// ResourceSlot sandbox - represents a fake sandbox that tracks resource requirements
/// but doesn't actually allocate resources
pub struct ResourceSlotSandbox {
    pub(crate) id: String,
    pub(crate) data: SandboxData,
    pub(crate) status: SandboxStatus,
    pub(crate) exit_signal: Arc<ExitSignal>,
    pub(crate) containers: HashMap<String, ResourceSlotContainer>,
    pub(crate) resource_info: ResourceInfo,
    pub(crate) started_at: Option<OffsetDateTime>,
}

/// ResourceSlot container - represents a fake container that tracks resource requirements
pub struct ResourceSlotContainer {
    pub(crate) data: ContainerData,
    pub(crate) resource_info: ResourceInfo,
}

/// Resource information extracted from sandbox/container configuration
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ResourceInfo {
    pub cpu_limit: Option<f64>,
    pub cpu_request: Option<f64>,
    pub memory_limit: Option<u64>,
    pub memory_request: Option<u64>,
    pub pid_limit: Option<u32>,
    pub storage_limit: Option<u64>,
    pub network_bandwidth: Option<u64>,
}

impl Default for ResourceInfo {
    fn default() -> Self {
        Self {
            cpu_limit: None,
            cpu_request: None,
            memory_limit: None,
            memory_request: None,
            pid_limit: None,
            storage_limit: None,
            network_bandwidth: None,
        }
    }
}

impl ResourceInfo {
    /// Extract resource information from sandbox data
    pub fn from_sandbox_data(data: &SandboxData) -> Self {
        let mut info = ResourceInfo::default();
        
        // Extract resources from CRI annotations if available
        // Note: annotations field may not be available in current version
        if let Some(spec) = &data.spec {
            let annotations = &spec.annotations;
            // CPU limits and requests
            if let Some(cpu_limit) = annotations.get("resources.limits.cpu") {
                if let Ok(limit) = cpu_limit.parse::<f64>() {
                    info.cpu_limit = Some(limit);
                }
            }
            if let Some(cpu_request) = annotations.get("resources.requests.cpu") {
                if let Ok(request) = cpu_request.parse::<f64>() {
                    info.cpu_request = Some(request);
                }
            }
            
            // Memory limits and requests
            if let Some(memory_limit) = annotations.get("resources.limits.memory") {
                if let Ok(limit) = memory_limit.parse::<u64>() {
                    info.memory_limit = Some(limit);
                }
            }
            if let Some(memory_request) = annotations.get("resources.requests.memory") {
                if let Ok(request) = memory_request.parse::<u64>() {
                    info.memory_request = Some(request);
                }
            }
            
            // PID limit
            if let Some(pid_limit) = annotations.get("resources.limits.pid") {
                if let Ok(limit) = pid_limit.parse::<u32>() {
                    info.pid_limit = Some(limit);
                }
            }
        }
        
        // Extract resources from spec if available
        if let Some(spec) = &data.spec {
            if let Some(linux) = &spec.linux {
                if let Some(resources) = &linux.resources {
                    // CPU resources
                    if let Some(cpu) = &resources.cpu {
                        if let Some(shares) = cpu.shares {
                            info.cpu_request = Some(shares as f64 / 1024.0);
                        }
                        if let Some(quota) = cpu.quota {
                            if let Some(period) = cpu.period {
                                info.cpu_limit = Some(quota as f64 / period as f64);
                            }
                        }
                    }
                    
                    // Memory resources
                    if let Some(memory) = &resources.memory {
                        if let Some(limit) = memory.limit {
                            info.memory_limit = Some(limit as u64);
                        }
                    }
                    
                    // PID resources
                    if let Some(pids) = &resources.pids {
                        let limit = pids.limit;
                        info.pid_limit = Some(limit as u32);
                    }
                }
            }
        }
        
        info
    }
    
    /// Extract resource information from container data
    pub fn from_container_data(data: &ContainerData) -> Self {
        let mut info = ResourceInfo::default();
        
        if let Some(spec) = &data.spec {
            if let Some(linux) = &spec.linux {
                if let Some(resources) = &linux.resources {
                    // CPU resources
                    if let Some(cpu) = &resources.cpu {
                        if let Some(shares) = cpu.shares {
                            info.cpu_request = Some(shares as f64 / 1024.0);
                        }
                        if let Some(quota) = cpu.quota {
                            if let Some(period) = cpu.period {
                                info.cpu_limit = Some(quota as f64 / period as f64);
                            }
                        }
                    }
                    
                    // Memory resources
                    if let Some(memory) = &resources.memory {
                        if let Some(limit) = memory.limit {
                            info.memory_limit = Some(limit as u64);
                        }
                    }
                    
                    // PID resources
                    if let Some(pids) = &resources.pids {
                        let limit = pids.limit;
                        info.pid_limit = Some(limit as u32);
                    }
                }
            }
        }
        
        info
    }
}

#[async_trait]
impl Sandboxer for ResourceSlotSandboxer {
    type Sandbox = ResourceSlotSandbox;

    async fn create(&self, id: &str, s: SandboxOption) -> Result<()> {
        info!("Creating ResourceSlot sandbox: {}", id);
        
        let resource_info = ResourceInfo::from_sandbox_data(&s.sandbox);
        debug!("Extracted resource info: {:?}", resource_info);
        
        let sandbox = ResourceSlotSandbox {
            id: id.to_string(),
            data: s.sandbox,
            status: SandboxStatus::Created,
            exit_signal: Arc::new(Default::default()),
            containers: HashMap::new(),
            resource_info,
            started_at: None,
        };
        
        let mut sandboxes = self.sandboxes.write().await;
        sandboxes.insert(id.to_string(), Arc::new(Mutex::new(sandbox)));
        
        info!("ResourceSlot sandbox {} created successfully", id);
        Ok(())
    }

    async fn start(&self, id: &str) -> Result<()> {
        info!("Starting ResourceSlot sandbox: {}", id);
        
        let sandbox = self.sandbox(id).await?;
        let mut sandbox = sandbox.lock().await;
        
        // Update status and timestamp
        sandbox.status = SandboxStatus::Running(0);
        sandbox.started_at = Some(OffsetDateTime::now_utc());
        
        // Simulate resource allocation logging
        info!("ResourceSlot sandbox {} resource simulation:", id);
        if let Some(cpu_limit) = sandbox.resource_info.cpu_limit {
            info!("  - CPU limit: {} cores", cpu_limit);
        }
        if let Some(memory_limit) = sandbox.resource_info.memory_limit {
            info!("  - Memory limit: {} bytes", memory_limit);
        }
        if let Some(pid_limit) = sandbox.resource_info.pid_limit {
            info!("  - PID limit: {}", pid_limit);
        }
        
        info!("ResourceSlot sandbox {} started successfully", id);
        Ok(())
    }

    async fn update(&self, id: &str, data: SandboxData) -> Result<()> {
        info!("Updating ResourceSlot sandbox: {}", id);
        
        let sandbox = self.sandbox(id).await?;
        let mut sandbox = sandbox.lock().await;
        
        // Update resource information
        sandbox.resource_info = ResourceInfo::from_sandbox_data(&data);
        sandbox.data = data;
        
        debug!("Updated resource info: {:?}", sandbox.resource_info);
        info!("ResourceSlot sandbox {} updated successfully", id);
        Ok(())
    }

    async fn sandbox(&self, id: &str) -> Result<Arc<Mutex<Self::Sandbox>>> {
        Ok(self
            .sandboxes
            .read()
            .await
            .get(id)
            .ok_or_else(|| Error::NotFound(id.to_string()))?
            .clone())
    }

    async fn stop(&self, id: &str, _force: bool) -> Result<()> {
        info!("Stopping ResourceSlot sandbox: {}", id);
        
        let sandbox = self.sandbox(id).await?;
        let mut sandbox = sandbox.lock().await;
        
        // Update status
        sandbox.status = SandboxStatus::Stopped(0, 0);
        
        // Signal exit
        sandbox.exit_signal.signal();
        
        info!("ResourceSlot sandbox {} stopped successfully", id);
        Ok(())
    }

    async fn delete(&self, id: &str) -> Result<()> {
        info!("Deleting ResourceSlot sandbox: {}", id);
        
        self.sandboxes.write().await.remove(id);
        
        info!("ResourceSlot sandbox {} deleted successfully", id);
        Ok(())
    }
}

#[async_trait]
impl Sandbox for ResourceSlotSandbox {
    type Container = ResourceSlotContainer;

    fn status(&self) -> Result<SandboxStatus> {
        Ok(self.status.clone())
    }

    async fn ping(&self) -> Result<()> {
        // Always return success for fake sandbox
        Ok(())
    }

    async fn container<'a>(&'a self, id: &str) -> Result<&'a Self::Container> {
        let container = self
            .containers
            .get(id)
            .ok_or_else(|| Error::NotFound(id.to_string()))?;
        Ok(container)
    }

    async fn append_container(&mut self, id: &str, options: ContainerOption) -> Result<()> {
        info!("Appending container {} to ResourceSlot sandbox {}", id, self.id);
        
        let resource_info = ResourceInfo::from_container_data(&options.container);
        debug!("Container resource info: {:?}", resource_info);
        
        let container = ResourceSlotContainer {
            data: options.container,
            resource_info,
        };
        
        self.containers.insert(id.to_string(), container);
        
        info!("Container {} appended successfully", id);
        Ok(())
    }

    async fn update_container(&mut self, id: &str, options: ContainerOption) -> Result<()> {
        info!("Updating container {} in ResourceSlot sandbox {}", id, self.id);
        
        let container = self.containers.get_mut(id)
            .ok_or_else(|| Error::NotFound(id.to_string()))?;
        
        // Update resource information
        container.resource_info = ResourceInfo::from_container_data(&options.container);
        container.data = options.container;
        
        debug!("Updated container resource info: {:?}", container.resource_info);
        info!("Container {} updated successfully", id);
        Ok(())
    }

    async fn remove_container(&mut self, id: &str) -> Result<()> {
        info!("Removing container {} from ResourceSlot sandbox {}", id, self.id);
        
        self.containers.remove(id)
            .ok_or_else(|| Error::NotFound(id.to_string()))?;
        
        info!("Container {} removed successfully", id);
        Ok(())
    }

    async fn exit_signal(&self) -> Result<Arc<ExitSignal>> {
        Ok(self.exit_signal.clone())
    }

    fn get_data(&self) -> Result<SandboxData> {
        Ok(self.data.clone())
    }
}

impl Container for ResourceSlotContainer {
    fn get_data(&self) -> Result<ContainerData> {
        Ok(self.data.clone())
    }
}
