package xiaozhi.modules.agent.dao;

import java.util.List;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;

import xiaozhi.modules.agent.entity.AgentChatHistoryEntity;

/**
 * {@link AgentChatHistoryEntity} Agent chat history Dao object
 *
 * @author Goody
 * @version 1.0, 2025/4/30
 * @since 1.0.0
 */
@Mapper
public interface AiAgentChatHistoryDao extends BaseMapper<AgentChatHistoryEntity> {

    /**
     * Delete chat history by agent ID
     *
     * @param agentId Agent ID
     */
    void deleteHistoryByAgentId(String agentId);

    /**
     * Delete audio by agent ID ID
     *
     * @param agentId Agent ID
     */
    void deleteAudioIdByAgentId(String agentId);

    /**
     * Get the list of all audio IDs by agent ID
     *
     * @param agentId Agent ID
     * @return Audio ID list
     */
    List<String> getAudioIdsByAgentId(String agentId);

    /**
     * Batch delete audio
     *
     * @param audioIds Audio ID list
     */
    void deleteAudioByIds(@Param("audioIds") List<String> audioIds);
}
