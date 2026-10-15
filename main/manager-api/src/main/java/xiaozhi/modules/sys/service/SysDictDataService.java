package xiaozhi.modules.sys.service;

import java.util.List;
import java.util.Map;

import xiaozhi.common.page.PageData;
import xiaozhi.common.service.BaseService;
import xiaozhi.modules.sys.dto.SysDictDataDTO;
import xiaozhi.modules.sys.entity.SysDictDataEntity;
import xiaozhi.modules.sys.vo.SysDictDataItem;
import xiaozhi.modules.sys.vo.SysDictDataVO;

/**
 * Data dictionary
 */
public interface SysDictDataService extends BaseService<SysDictDataEntity> {

    /**
     * Query data dictionary information (paginated)
     *
     * @param params query parameters, including pagination info and query conditions
     * @return the paginated data dictionary query result
     */
    PageData<SysDictDataVO> page(Map<String, Object> params);

    /**
     * Get the data dictionary entity by ID
     *
     * @param id unique identifier of the data dictionary entity
     * @return the details of the data dictionary entity
     */
    SysDictDataVO get(Long id);

    /**
     * Save a new data dictionary item
     *
     * @param dto data transfer object for saving the data dictionary item
     */
    void save(SysDictDataDTO dto);

    /**
     * Update a data dictionary item
     *
     * @param dto data transfer object for updating the data dictionary item
     */
    void update(SysDictDataDTO dto);

    /**
     * Delete data dictionary items
     *
     * @param ids array of IDs of the data dictionary items to delete
     */
    void delete(Long[] ids);

    /**
     * Delete the dictionary data for the given dictionary type ID
     *
     * @param dictTypeId Dictionary type ID
     */
    void deleteByTypeId(Long dictTypeId);

    /**
     * Get the dictionary data list by dictionary type
     *
     * @param dictType Dictionary type
     * @return the dictionary data list
     */
    List<SysDictDataItem> getDictDataByType(String dictType);

}