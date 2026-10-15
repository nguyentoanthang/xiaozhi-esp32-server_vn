package xiaozhi.modules.timbre.service;

import java.util.List;

import xiaozhi.common.page.PageData;
import xiaozhi.common.service.BaseService;
import xiaozhi.modules.model.dto.VoiceDTO;
import xiaozhi.modules.timbre.dto.TimbreDataDTO;
import xiaozhi.modules.timbre.dto.TimbrePageDTO;
import xiaozhi.modules.timbre.entity.TimbreEntity;
import xiaozhi.modules.timbre.vo.TimbreDetailsVO;

/**
 * Voice (timbre) service layer definition
 * 
 * @author zjy
 * @since 2025-3-21
 */
public interface TimbreService extends BaseService<TimbreEntity> {
    /**
     * Get the voices under the specified TTS (paginated)
     * 
     * @param dto pagination search parameters
     * @return paginated voice list data
     */
    PageData<TimbreDetailsVO> page(TimbrePageDTO dto);

    /**
     * Get the details of the voice with the given ID
     * 
     * @param timbreId voice table ID
     * @return Voice information
     */
    TimbreDetailsVO get(String timbreId);

    /**
     * Save voice information
     * 
     * @param dto data to save
     */
    void save(TimbreDataDTO dto);

    /**
     * Save voice information
     * 
     * @param timbreId ID to update
     * @param dto      data to update
     */
    void update(String timbreId, TimbreDataDTO dto);

    /**
     * Batch delete voices
     * 
     * @param ids list of voice IDs to delete
     */
    void delete(String[] ids);

    List<VoiceDTO> getVoiceNames(String ttsModelId, String voiceName);

    /**
     * Get the first valid language configured for a regular or cloned voice.
     *
     * @param id voice ID
     * @return the default language; null if the voice does not exist or has no valid language configured
     */
    String getDefaultLanguageById(String id);

    /**
     * Get the voice name by ID
     * 
     * @param id voice ID
     * @return Voice name
     */
    String getTimbreNameById(String id);

    /**
     * Get voice information by voice code
     * 
     * @param ttsModelId voice model ID
     * @param voiceCode  Voice code
     * @return Voice information
     */
    VoiceDTO getByVoiceCode(String ttsModelId, String voiceCode);
}
