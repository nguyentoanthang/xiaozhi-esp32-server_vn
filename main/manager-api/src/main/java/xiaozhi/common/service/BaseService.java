package xiaozhi.common.service;

import java.io.Serializable;
import java.util.Collection;

import com.baomidou.mybatisplus.core.conditions.Wrapper;

/**
 * Base service interface; all Service interfaces must extend it
 * Copyright (c) Renren Open Source All rights reserved.
 * Website: https://www.renren.io
 */
public interface BaseService<T> {
    Class<T> currentModelClass();

    /**
     * <p>
     * Insert a record (selective fields, strategy insert)
     * </p>
     *
     * @param entity Entity object
     */
    boolean insert(T entity);

    /**
     * <p>
     * Insert (batch). This method does not support Oracle, SQL Server
     * </p>
     *
     * @param entityList Entity object collection
     */
    boolean insertBatch(Collection<T> entityList);

    /**
     * <p>
     * Insert (batch). This method does not support Oracle, SQL Server
     * </p>
     *
     * @param entityList Entity object collection
     * @param batchSize  Insert batch size
     */
    boolean insertBatch(Collection<T> entityList, int batchSize);

    /**
     * <p>
     * Selectively update by ID
     * </p>
     *
     * @param entity Entity object
     */
    boolean updateById(T entity);

    /**
     * <p>
     * Update records by the whereEntity condition
     * </p>
     *
     * @param entity        Entity object
     * @param updateWrapper Entity object wrapper class
     *                      {@link com.baomidou.mybatisplus.core.conditions.update.UpdateWrapper}
     */
    boolean update(T entity, Wrapper<T> updateWrapper);

    /**
     * <p>
     * Batch update by ID
     * </p>
     *
     * @param entityList Entity object collection
     */
    boolean updateBatchById(Collection<T> entityList);

    /**
     * <p>
     * Batch update by ID
     * </p>
     *
     * @param entityList Entity object collection
     * @param batchSize  Update batch size
     */
    boolean updateBatchById(Collection<T> entityList, int batchSize);

    /**
     * <p>
     * Query by ID
     * </p>
     *
     * @param id Primary key ID
     */
    T selectById(Serializable id);

    /**
     * <p>
     * Delete by ID
     * </p>
     *
     * @param id Primary key ID
     */
    boolean deleteById(Serializable id);

    /**
     * <p>
     * Delete (batch delete by ID)
     * </p>
     *
     * @param idList Primary key ID list
     */
    boolean deleteBatchIds(Collection<? extends Serializable> idList);
}