package xiaozhi.modules.agent.service;

import java.util.List;
import java.util.Map;

import xiaozhi.common.page.PageData;
import xiaozhi.common.service.BaseService;
import xiaozhi.modules.agent.dto.AgentCreateDTO;
import xiaozhi.modules.agent.dto.AgentDTO;
import xiaozhi.modules.agent.dto.AgentMemoryDTO;
import xiaozhi.modules.agent.dto.AgentUpdateDTO;
import xiaozhi.modules.agent.entity.AgentEntity;
import xiaozhi.modules.agent.vo.AgentInfoVO;

/**
 * Agent table handling service
 *
 * @author Goody
 * @version 1.0, 2025/4/30
 * @since 1.0.0
 */
public interface AgentService extends BaseService<AgentEntity> {
    /**
     * Get the admin agent list
     *
     * @param params Query parameters
     * @return Paged data
     */
    PageData<AgentEntity> adminAgentList(Map<String, Object> params);

    /**
     * Get the agent by ID
     *
     * @param id Agent ID
     * @return Agent entity
     */
    AgentInfoVO getAgentById(String id);

    /**
     * Get an agent the current user has access to, by ID
     *
     * @param id     Agent ID
     * @param userId Current user ID
     * @return Agent entity
     */
    AgentInfoVO getAgentById(String id, Long userId);

    /**
     * Insert agent
     *
     * @param entity Agent entity
     * @return Whether successful
     */
    boolean insert(AgentEntity entity);

    /**
     * Delete agents by user ID
     *
     * @param userId User ID
     */
    void deleteAgentByUserId(Long userId);

    /**
     * Delete an agent and its associated data
     *
     * @param agentId Agent ID
     */
    void deleteAgent(String agentId);

    /**
     * Get the user's agent list
     *
     * @param userId User ID
     * @param keyword Search keyword
     * @param searchType Search type (name - search by name, mac - search by MAC address)
     * @return Agent list
     */
    List<AgentDTO> getUserAgents(Long userId, String keyword, String searchType);

    /**
     * Get the device count by agent ID
     *
     * @param agentId Agent ID
     * @return Device count
     */
    Integer getDeviceCountByAgentId(String agentId);

    /**
     * Query the default agent info of the device by device MAC address
     *
     * @param macAddress Device MAC address
     * @return Default agent info; when it does not exist, returns null
     */
    AgentEntity getDefaultAgentByMacAddress(String macAddress);

    /**
     * Check whether the user has permission to access the agent
     *
     * @param agentId Agent ID
     * @param userId  User ID
     * @return Whether permitted
     */
    boolean checkAgentPermission(String agentId, Long userId);

    /**
     * Update agent
     *
     * @param agentId Agent ID
     * @param dto     Information required to update the agent
     */
    void updateAgentById(String agentId, AgentUpdateDTO dto);

    /**
     * Update an agent the current user has access to
     *
     * @param agentId Agent ID
     * @param dto     Information required to update the agent
     * @param userId  Current user ID
     */
    void updateAgentById(String agentId, AgentUpdateDTO dto, Long userId);

    /**
     * Update the memory of an agent the current user has access to, by device MAC address
     *
     * @param macAddress Device MAC address
     * @param dto        Agent memory
     * @param userId     Current user ID
     */
    void updateAgentMemoryByDeviceMacAddress(String macAddress, AgentMemoryDTO dto, Long userId);

    /**
     * Delete an agent the current user has access to
     *
     * @param agentId Agent ID
     * @param userId  Current user ID
     */
    void deleteAgentById(String agentId, Long userId);

    /**
     * Update agent
     *
     * @param agentId        Agent ID
     * @param dto            Information required to update the agent
     * @param createSnapshot Whether to create a configuration snapshot
     */
    void updateAgentById(String agentId, AgentUpdateDTO dto, boolean createSnapshot);

    /**
     * Create agent
     *
     * @param dto Information required to create the agent
     * @return The created agent ID
     */
    String createAgent(AgentCreateDTO dto);


}
