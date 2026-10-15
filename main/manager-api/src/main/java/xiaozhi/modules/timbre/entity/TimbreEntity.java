package xiaozhi.modules.timbre.entity;

import java.util.Date;

import com.baomidou.mybatisplus.annotation.FieldFill;
import com.baomidou.mybatisplus.annotation.FieldStrategy;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableName;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * Voice table entity class
 * 
 * @author zjy
 * @since 2025-3-21
 */
@Data
@EqualsAndHashCode(callSuper = false)
@TableName("ai_tts_voice")
@Schema(description = "Voice information")
public class TimbreEntity {

    @Schema(description = "id")
    private String id;

    @Schema(description = "Language")
    private String languages;

    @Schema(description = "Voice name")
    private String name;

    @Schema(description = "Remarks")
    private String remark;

    @Schema(description = "Reference audio path")
    private String referenceAudio;

    @Schema(description = "Reference text")
    private String referenceText;

    @Schema(description = "Sort order")
    @TableField(updateStrategy = FieldStrategy.NOT_NULL)
    private Long sort;

    @Schema(description = "Corresponding TTS model primary key")
    private String ttsModelId;

    @Schema(description = "Voice code")
    private String ttsVoice;

    @Schema(description = "Audio playback URL")
    private String voiceDemo;

    @Schema(description = "Updated by")
    @TableField(fill = FieldFill.UPDATE)
    private Long updater;

    @Schema(description = "Update time")
    @TableField(fill = FieldFill.UPDATE)
    private Date updateDate;

    @Schema(description = "Created by")
    @TableField(fill = FieldFill.INSERT)
    private Long creator;

    @Schema(description = "Create time")
    @TableField(fill = FieldFill.INSERT)
    private Date createDate;

}
