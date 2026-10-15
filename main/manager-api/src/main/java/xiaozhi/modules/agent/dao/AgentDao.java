package xiaozhi.modules.agent.dao;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import org.apache.ibatis.annotations.Select;
import xiaozhi.common.dao.BaseDao;
import xiaozhi.modules.agent.entity.AgentEntity;
import xiaozhi.modules.agent.vo.AgentInfoVO;

@Mapper
public interface AgentDao extends BaseDao<AgentEntity> {
    /**
     * Get the agent's device count
     * 
     * @param agentId Agent ID
     * @return Device count
     */
    Integer getDeviceCountByAgentId(@Param("agentId") String agentId);

    /**
     * Query the default agent info of the device by device MAC address
     *
     * @param macAddress Device MAC address
     * @return Default agent info
     */
    @Select(" SELECT a.* FROM ai_device d " +
            " LEFT JOIN ai_agent a ON d.agent_id = a.id " +
            " WHERE d.mac_address = #{macAddress} " +
            " ORDER BY d.id DESC LIMIT 1")
    AgentEntity getDefaultAgentByMacAddress(@Param("macAddress") String macAddress);

    /**
     * Query agent info by id, including plugin info
     *
     * @param agentId Agent ID
     */
    AgentInfoVO selectAgentInfoById(@Param("agentId") String agentId);

    /**
     * Lock the agent's main record to serialize configuration writes for the same agent
     *
     * @param agentId Agent ID
     */
    AgentEntity selectByIdForUpdate(@Param("agentId") String agentId);

    /**
     * Write exactly the agent fields covered by the snapshot, including null values in the target snapshot.
     * Do not update fields that are not part of the snapshot, such as the owning user and creation info.
     *
     * @param agent Agent with the target snapshot applied
     * @return Number of affected rows
     */
    int updateSnapshotFields(@Param("agent") AgentEntity agent);
}
