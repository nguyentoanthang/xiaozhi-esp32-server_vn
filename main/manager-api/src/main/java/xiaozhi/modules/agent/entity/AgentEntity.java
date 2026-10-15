package xiaozhi.modules.agent.entity;

import java.math.BigDecimal;
import java.util.Date;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

@Data
@TableName("ai_agent")
@Schema(description = "Agent information")
public class AgentEntity {

    @TableId(type = IdType.ASSIGN_UUID)
    @Schema(description = "Agent unique identifier")
    private String id;

    @Schema(description = "Owning user ID")
    private Long userId;

    @Schema(description = "Agent code")
    private String agentCode;

    @Schema(description = "Agent name")
    private String agentName;

    @Schema(description = "Speech recognition model identifier")
    private String asrModelId;

    @Schema(description = "Voice activity detection identifier")
    private String vadModelId;

    @Schema(description = "Large language model identifier")
    private String llmModelId;

    @Schema(description = "Small language model identifier")
    private String slmModelId;

    @Schema(description = "VLLM model identifier")
    private String vllmModelId;

    @Schema(description = "Speech synthesis model identifier")
    private String ttsModelId;

    @Schema(description = "Voice identifier")
    private String ttsVoiceId;

    @Schema(description = "Voice language")
    private String ttsLanguage;

    @Schema(description = "TTS Volume")
    private Integer ttsVolume;

    @Schema(description = "TTS Speech rate")
    private Integer ttsRate;

    @Schema(description = "TTS Pitch")
    private Integer ttsPitch;

    @Schema(description = "Memory model identifier")
    private String memModelId;

    @Schema(description = "Intent model identifier")
    private String intentModelId;

    @Schema(description = "Chat history configuration (0 none, 1 text only, 2 text and audio)")
    private Integer chatHistoryConf;

    @Schema(description = "Role setting parameters")
    private String systemPrompt;

    @Schema(description = "Summary memory", example = "Build a growable dynamic memory network that preserves key information within limited space while intelligently maintaining how the information evolves\n" +
            "Based on the conversation records, summarize the important information about the user so as to provide more personalized service in future conversations", requiredMode = Schema.RequiredMode.NOT_REQUIRED)
    private String summaryMemory;

    @Schema(description = "Language code")
    private String langCode;

    @Schema(description = "Interaction language")
    private String language;

    @Schema(description = "Sort")
    private Integer sort;

    @Schema(description = "Creator")
    private Long creator;

    @Schema(description = "Creation time")
    private Date createdAt;

    @Schema(description = "Updater")
    private Long updater;

    @Schema(description = "Update time")
    private Date updatedAt;
}
