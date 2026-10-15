package xiaozhi.modules.voiceclone.dto;

import java.util.Date;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

/**
 * Voice clone response DTO
 * Used to show voice clone information to the frontend, including the model name and username
 */
@Data
@Schema(description = "Voice clone response DTO")
public class VoiceCloneResponseDTO {

    @Schema(description = "Unique identifier")
    private String id;

    @Schema(description = "Voice name")
    private String name;

    @Schema(description = "Model ID")
    private String modelId;

    @Schema(description = "Model name")
    private String modelName;

    @Schema(description = "Voice ID")
    private String voiceId;

    @Schema(description = "Language")
    private String languages;

    @Schema(description = "User ID (references the user table)")
    private Long userId;

    @Schema(description = "Username")
    private String userName;

    @Schema(description = "Training status: 0 pending, 1 training, 2 succeeded, 3 failed")
    private Integer trainStatus;

    @Schema(description = "Training error reason")
    private String trainError;

    @Schema(description = "Create time")
    private Date createDate;

    @Schema(description = "Whether audio data exists")
    private Boolean hasVoice;
}