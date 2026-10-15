package xiaozhi.modules.knowledge.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import xiaozhi.modules.knowledge.rag.KnowledgeBaseAdapterFactory;

/**
 * Knowledge base configuration class
 * Configures knowledge-base-related Beans
 */
@Configuration
public class KnowledgeBaseConfig {

    /**
     * Provides the Bean instance of KnowledgeBaseAdapterFactory
     * @return KnowledgeBaseAdapterFactory instance
     */
    @Bean
    public KnowledgeBaseAdapterFactory knowledgeBaseAdapterFactory() {
        return new KnowledgeBaseAdapterFactory();
    }
}