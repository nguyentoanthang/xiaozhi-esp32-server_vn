package xiaozhi.modules.agent.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;
import lombok.EqualsAndHashCode;
import xiaozhi.modules.agent.dto.ContextProviderDTO;
import xiaozhi.modules.agent.entity.AgentEntity;
import xiaozhi.modules.agent.entity.AgentPluginMapping;

import java.util.List;

/**
 * Agent information response VO
 * This directly extends the Agent entity class AgentEntity; if the returned fields need to be standardized later, copy the fields out
 */
@EqualsAndHashCode(callSuper = true)
@Data
public class AgentInfoVO extends AgentEntity
{
    @Schema(description = "Plugin list Id")
    private List<AgentPluginMapping> functions;

    @Schema(description = "Context source configuration")
    private List<ContextProviderDTO> contextProviders;

    @Schema(description = "Replacement word file ID list")
    private List<String> correctWordFileIds;

    @Schema(description = "Current configuration version number")
    private Integer currentVersionNo;
}
