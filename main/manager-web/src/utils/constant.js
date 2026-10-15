const HAVE_NO_RESULT = 'N/A'
export default {
    HAVE_NO_RESULT, // Project configuration
    PAGE: {
        LOGIN: '/login',
    },
    STORAGE_KEY: {
        TOKEN: 'TOKEN',
        PUBLIC_KEY: 'PUBLIC_KEY',
        USER_TYPE: 'USER_TYPE'
    },
    Lang: {
        'en': 'en'
    },
    FONT_SIZE: {
        'big': 'big',
        'normal': 'normal',
    }, // Get a key from the map
    get(map, key) {
        return map[key] || HAVE_NO_RESULT
    }
}
