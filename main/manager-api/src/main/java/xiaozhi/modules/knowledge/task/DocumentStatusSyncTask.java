package xiaozhi.modules.knowledge.task;

import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import lombok.AllArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import xiaozhi.modules.knowledge.service.KnowledgeFilesService;

/**
 * Scheduled task for syncing knowledge base document status
 * 
 * Purpose:
 * 1. Automatically scan documents in the "RUNNING" (parsing) state
 * 2. Call the RAGFlow API to get the latest status
 * 3. When the status flips (RUNNING -> SUCCESS/FAIL), update the database synchronously
 * 4. [Key] When parsing succeeds, compensate by updating the knowledge base statistics (TokenCount)
 */
@Component
@AllArgsConstructor
@Slf4j
public class DocumentStatusSyncTask {

    private final KnowledgeFilesService knowledgeFilesService;

    /**
     * Run the sync once every 30 seconds
     * Uses fixedDelay to ensure the next run starts 30 seconds after the previous one finishes, preventing a backlog
     */
    @Scheduled(fixedDelay = 30000)
    public void syncRunningDocuments() {
        try {
            // log.debug("Start executing the document status sync task...");
            knowledgeFilesService.syncRunningDocuments();
        } catch (Exception e) {
            log.error("Document status sync task error", e);
        }
    }
}
