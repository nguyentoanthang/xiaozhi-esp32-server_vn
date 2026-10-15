// Feature configuration utility
import Api from "@/apis/api";
import store from "@/store";

class FeatureManager {
    constructor() {
        this.defaultFeatures = {
            voiceprintRecognition: {
                name: 'feature.voiceprintRecognition.name',
                enabled: false,
                description: 'feature.voiceprintRecognition.description'
            },
            voiceClone: {
                name: 'feature.voiceClone.name',
                enabled: false,
                description: 'feature.voiceClone.description'
            },
            knowledgeBase: {
                name: 'feature.knowledgeBase.name',
                enabled: false,
                description: 'feature.knowledgeBase.description'
            },
            mcpAccessPoint: {
                name: 'feature.mcpAccessPoint.name',
                enabled: false,
                description: 'feature.mcpAccessPoint.description'
            },
            vad: {
                name: 'feature.vad.name',
                enabled: false,
                description: 'feature.vad.description'
            },
            asr: {
                name: 'feature.asr.name',
                enabled: false,
                description: 'feature.asr.description'
            },
            addressBook: {
                name: 'feature.addressBook.name',
                enabled: false,
                description: 'feature.addressBook.description'
            }
        };
        this.currentFeatures = { ...this.defaultFeatures }; // Current in-memory configuration
        this.initialized = false;
        this.initPromise = null;
    }

    /**
     * Wait for initialization to complete
     */
    async waitForInitialization() {
        if (!this.initPromise) {
            this.initPromise = this.init();
        }
        await this.initPromise;
        return this.initialized;
    }

    /**
     * Initialize the feature configuration
     */
    async init() {
        try {
            // Get the configuration from the pub-config API
            const config = await this.getConfigFromPubConfig();
            if (config) {
                this.currentFeatures = { ...config }; // Save to memory
                this.initialized = true;
                return;
            }
        } catch (error) {
            console.warn('Failed to get configuration from the pub-config API:', error);
        }

        // pub-config API failed, use the default configuration
        this.currentFeatures = { ...this.defaultFeatures }; // Save the default configuration to memory
        this.initialized = true;
    }

    /**
     * Update the config cache
     */
    updateConfigCache(config) {
        store.commit('setPubConfig', config);
        localStorage.setItem('pubConfig', JSON.stringify(config));
    }

    /**
     * Get the configuration from the pub-config API
     */
    async getConfigFromPubConfig() {
        return new Promise((resolve) => {
            // Call the pub-config API directly to get the configuration
            Api.user.getPubConfig((result) => {
                // Check the structure of the returned result
                if (result && result.status === 200) {
                    // Check whether there is a data field
                    if (result.data) {
                        const configCache = result.data.data || {};
                        // Check whether there is a code field; if so, decide based on code
                        if (result.data.code !== undefined) {
                            if (result.data.code === 0 && result.data.data && result.data.data.systemWebMenu) {
                                try {
                                    let config;
                                    if (typeof result.data.data.systemWebMenu === 'string') {
                                        // If it is a string, parse the JSON
                                        config = JSON.parse(result.data.data.systemWebMenu);
                                    } else {
                                        // If it is already an object, use it directly
                                        config = result.data.data.systemWebMenu;
                                    }

                                    // Check whether the configuration contains a features object
                                    if (config && config.features) {
                                        // Make sure the knowledgeBase feature exists and is configured correctly
                                        if (!config.features.knowledgeBase) {
                                            console.warn('knowledgeBase feature missing in the configuration, merging the default configuration');
                                            config.features = { ...this.defaultFeatures, ...config.features };
                                        }
                                        resolve(config.features);
                                    } else {
                                        console.warn('features object missing in the configuration, using the default configuration');
                                        resolve(this.defaultFeatures);
                                    }
                                    configCache.systemWebMenu = config;
                                } catch (error) {
                                    console.warn('Failed to process the systemWebMenu configuration:', error);
                                    resolve(null);
                                }
                            } else {
                                console.warn('API returned a non-zero code or lacks required data, using the default configuration');
                                resolve(null);
                            }
                        } else {
                            // If there is no code field, check systemWebMenu directly
                            if (result.data && result.data.systemWebMenu) {
                                try {
                                    let config;
                                    if (typeof result.data.systemWebMenu === 'string') {
                                        // If it is a string, parse the JSON
                                        config = JSON.parse(result.data.systemWebMenu);
                                    } else {
                                        // If it is already an object, use it directly
                                        config = result.data.systemWebMenu;
                                    }

                                    // Check whether the configuration contains a features object
                                    if (config && config.features) {
                                        // Make sure the knowledgeBase feature exists and is configured correctly
                                        if (!config.features.knowledgeBase) {
                                            console.warn('knowledgeBase feature missing in the configuration, merging the default configuration');
                                            config.features = { ...this.defaultFeatures, ...config.features };
                                        }
                                        resolve(config.features);
                                    } else {
                                        console.warn('features object missing in the configuration, using the default configuration');
                                        resolve(this.defaultFeatures);
                                    }
                                    configCache.systemWebMenu = config;
                                } catch (error) {
                                    console.warn('Failed to process the systemWebMenu configuration:', error);
                                    resolve(null);
                                }
                            } else {
                                console.warn('API response lacks systemWebMenu data, using the default configuration');
                                resolve(null);
                            }
                        }
                        this.updateConfigCache(configCache)
                    } else {
                        console.warn('API response lacks the data field, using the default configuration');
                        resolve(null);
                    }
                } else {
                    console.warn('pub-config API call failed, using the default configuration');
                    resolve(null);
                }
            });
        });
    }

    /**
     * Get the current configuration
     */
    getCurrentConfig() {
        // Return the current in-memory configuration
        return this.currentFeatures;
    }

    /**
     * Save the configuration to the backend API
     */
    async saveConfig(config) {
        try {
            // Update the in-memory configuration
            this.currentFeatures = { ...config };

            // Save to the backend API asynchronously
            this.saveConfigToAPI(config).catch(error => {
                console.warn('Failed to save the configuration to the API:', error);
            }).finally(() => {
                this.init()
            });

            // Trigger the configuration change event
            window.dispatchEvent(new CustomEvent('featureConfigChanged', {
                detail: config
            }));
        } catch (error) {
            console.error('Failed to save feature configuration:', error);
        }
    }

    /**
     * Save the configuration to the backend API
     */
    async saveConfigToAPI(config) {
        return new Promise((resolve) => {
            // Update the parameter directly using the known ID (600)
            Api.admin.updateParam(
                {
                    id: 600,
                    paramCode: 'system-web.menu',
                    paramValue: JSON.stringify({
                        features: config,
                        groups: {
                            featureManagement: ["voiceprintRecognition", "voiceClone", "knowledgeBase", "mcpAccessPoint", "addressBook"],
                            voiceManagement: ["vad", "asr"]
                        }
                    }),
                    valueType: 'json',
                    remark: 'System feature menu configuration'
                },
                (updateResult) => {
                    if (updateResult.code === 0) {
                        resolve();
                    } else {
                        // If the update fails, the parameter may not exist or another error occurred; log it but do not block saving to localStorage
                        console.warn('Failed to update parameter:', updateResult.msg);
                        resolve(); // do not block saving to localStorage
                    }
                },
                (error) => {
                    console.warn('Failed to update parameter:', error);
                    resolve(); // do not block saving to localStorage
                }
            );
        });
    }



    /**
     * Get all feature configurations
     */
    getAllFeatures() {
        return this.getCurrentConfig();
    }

    /**
     * Get a simplified configuration object (for home page components)
     */
    getConfig() {
        const features = this.getAllFeatures();
        return {
            voiceprintRecognition: features.voiceprintRecognition?.enabled || false,
            voiceClone: features.voiceClone?.enabled || false,
            knowledgeBase: features.knowledgeBase?.enabled || false,
            mcpAccessPoint: features.mcpAccessPoint?.enabled || false,
            vad: features.vad?.enabled || false,
            asr: features.asr?.enabled || false,
            addressBook: features.addressBook?.enabled || false
        };
    }

    /**
     * Get the status of the specified feature
     */
    getFeatureStatus(featureKey) {
        const features = this.getAllFeatures();
        return features[featureKey]?.enabled || false;
    }

    /**
     * Set feature status
     */
    setFeatureStatus(featureKey, enabled) {
        const features = this.getAllFeatures();
        if (features[featureKey]) {
            features[featureKey].enabled = enabled;
            this.saveConfig(features);
            return true;
        }
        return false;
    }

    /**
     * Enable feature
     */
    enableFeature(featureKey) {
        return this.setFeatureStatus(featureKey, true);
    }

    /**
     * Disable feature
     */
    disableFeature(featureKey) {
        return this.setFeatureStatus(featureKey, false);
    }

    /**
     * Toggle feature status
     */
    toggleFeature(featureKey) {
        const currentStatus = this.getFeatureStatus(featureKey);
        return this.setFeatureStatus(featureKey, !currentStatus);
    }

    /**
     * Reset all features to their default state
     */
    resetToDefault() {
        this.saveConfig(this.defaultFeatures);
    }

    /**
     * Batch update feature status
     */
    updateFeatures(featureUpdates) {
        const features = this.getAllFeatures();
        Object.keys(featureUpdates).forEach(featureKey => {
            if (features[featureKey]) {
                features[featureKey].enabled = featureUpdates[featureKey];
            } else if (this.defaultFeatures[featureKey]) {
                features[featureKey] = { ...this.defaultFeatures[featureKey] };
                features[featureKey].enabled = featureUpdates[featureKey];
            }
        });
        this.saveConfig(features);
    }

    /**
     * Get the list of enabled features
     */
    getEnabledFeatures() {
        const features = this.getAllFeatures();
        return Object.keys(features).filter(key => features[key].enabled);
    }

    /**
     * Check whether a feature is enabled
     */
    isFeatureEnabled(featureKey) {
        return this.getFeatureStatus(featureKey);
    }
}

// Create the singleton instance
const featureManager = new FeatureManager();

export default featureManager;