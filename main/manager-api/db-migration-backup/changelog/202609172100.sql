-- Add the Serply search source to the web search plugin

UPDATE `ai_model_provider`
SET `fields` = JSON_SET(
    `fields`,
    '$[0].label',
    'Search source: metaso / tavily / serply'
)
WHERE `id` = 'SYSTEM_PLUGIN_WEB_SEARCH';
