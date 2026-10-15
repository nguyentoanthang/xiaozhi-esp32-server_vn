package xiaozhi.modules.sys.service;

import java.util.List;
import java.util.Map;

import xiaozhi.common.page.PageData;
import xiaozhi.common.service.BaseService;
import xiaozhi.modules.sys.dto.SysParamsDTO;
import xiaozhi.modules.sys.entity.SysParamsEntity;

/**
 * Parameter management
 */
public interface SysParamsService extends BaseService<SysParamsEntity> {

    PageData<SysParamsDTO> page(Map<String, Object> params);

    List<SysParamsDTO> list(Map<String, Object> params);

    SysParamsDTO get(Long id);

    void save(SysParamsDTO dto);

    void update(SysParamsDTO dto);

    void delete(String[] ids);

    /**
     * Get the parameter value by parameter code
     *
     * @param paramCode Parameter code
     * @param fromCache whether to read from the cache
     */
    String getValue(String paramCode, Boolean fromCache);

    /**
     * Get the value as an Object by parameter code
     *
     * @param paramCode Parameter code
     * @param clazz     the Object type
     */
    <T> T getValueObject(String paramCode, Class<T> clazz);

    /**
     * Update value by parameter code
     *
     * @param paramCode  Parameter code
     * @param paramValue Parameter value
     */
    int updateValueByCode(String paramCode, String paramValue);

    /**
     * Initialize the server secret
     */
    void initServerSecret();

    /**
     * Get the system function menu configuration
     *
     * @param fromCache whether to read from the cache
     * @return the system function menu configuration as a JSON string
     */
    String getSystemWebMenu(boolean fromCache);

    /**
     * Update the system function menu configuration (automatically cleans up plugins tied to features)
     *
     * @param configJson the new system function menu configuration JSON
     */
    void updateSystemWebMenu(String configJson);
}
