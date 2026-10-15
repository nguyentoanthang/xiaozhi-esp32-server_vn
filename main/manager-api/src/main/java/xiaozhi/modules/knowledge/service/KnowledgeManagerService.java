package xiaozhi.modules.knowledge.service;

import java.util.List;

/**
 * Domain orchestration service for the knowledge base module
 * Handles complex business processes spanning KnowledgeBase and KnowledgeFiles, completely resolving circular dependencies between Services.
 */
public interface KnowledgeManagerService {

    /**
     * Cascade delete a knowledge base and all its documents (including local DB and RAGFlow remote data)
     * 
     * @param datasetId knowledge base ID
     */
    void deleteDatasetWithFiles(String datasetId);

    /**
     * Batch cascade delete knowledge bases
     * 
     * @param datasetIds knowledge base ID list
     */
    void batchDeleteDatasetsWithFiles(List<String> datasetIds);
}
