package xiaozhi.modules.voiceclone.service;

import java.util.List;
import java.util.Map;

import org.springframework.web.multipart.MultipartFile;

import xiaozhi.common.page.PageData;
import xiaozhi.common.service.BaseService;
import xiaozhi.modules.voiceclone.dto.VoiceCloneDTO;
import xiaozhi.modules.voiceclone.dto.VoiceCloneResponseDTO;
import xiaozhi.modules.voiceclone.entity.VoiceCloneEntity;

/**
 * Voice clone management
 */
public interface VoiceCloneService extends BaseService<VoiceCloneEntity> {

    /**
     * Paginated query
     */
    PageData<VoiceCloneEntity> page(Map<String, Object> params);

    /**
     * Save voice clone
     */
    void save(VoiceCloneDTO dto);

    /**
     * Batch delete
     */
    void delete(String[] ids);

    /**
     * Query the voice clone list by user ID
     * 
     * @param userId User ID
     * @return the voice clone list
     */
    List<VoiceCloneEntity> getByUserId(Long userId);

    /**
     * Paginated query of voice clones with model name and username
     */
    PageData<VoiceCloneResponseDTO> pageWithNames(Map<String, Object> params);

    /**
     * Query voice clone information with model name and username by ID
     */
    VoiceCloneResponseDTO getByIdWithNames(String id);

    /**
     * Query the voice clone list with model names by user ID
     */
    List<VoiceCloneResponseDTO> getByUserIdWithNames(Long userId);

    /**
     * Upload audio file
     */
    void uploadVoice(String id, MultipartFile voiceFile) throws Exception;

    /**
     * Update the voice clone name
     */
    void updateName(String id, String name);

    /**
     * Get the audio data
     */
    byte[] getVoiceData(String id);

    /**
     * Clone audio by calling Volcano Engine for voice cloning training
     * 
     * @param cloneId voice clone record ID
     */
    void cloneAudio(String cloneId);
}
