package xiaozhi.modules.agent.service;

import xiaozhi.common.service.BaseService;
import xiaozhi.modules.agent.entity.AgentContextProviderEntity;

public interface AgentContextProviderService extends BaseService<AgentContextProviderEntity> {
    /**
     * Get context source configuration by agent ID
     * @param agentId Agent ID
     * @return Context source configuration entity
     */
    AgentContextProviderEntity getByAgentId(String agentId);

    /**
     * Save or update context source configuration
     * @param entity entity
     */
    void saveOrUpdateByAgentId(AgentContextProviderEntity entity);

    /**
     * Delete context source configuration by agent ID
     * @param agentId Agent ID
     */
    void deleteByAgentId(String agentId);
}
