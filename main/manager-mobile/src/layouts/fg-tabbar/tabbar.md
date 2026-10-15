# tabbar Overview

`tabbar` has `4 types`:

- 0 `No tabbar`: only one page entry, no `tabbar` shown at the bottom; commonly used for temporary campaign pages.
- 1 `Native tabbar`: uses `switchTab` to switch tabs, and `tabbar` pages are cached.
  - Pros: built-in native tabbar, rendered first, cached.
  - Cons: only 2 sets of images can be used to switch between selected and unselected states; changing colors requires replacing the images (or using iconfont).
- 2 `Custom tabbar with cache`: uses `switchTab` to switch tabs, and `tabbar` pages are cached. It uses the `tabbar` component of a third-party UI library and hides the native `tabbar`.
  - Pros: any `svg icon` can be configured, switching font colors is easy, cached, and fancy animations are possible.
  - Cons: the tabbar flickers on the first click.
- 3 `Custom tabbar without cache`: uses `navigateTo` to switch `tabbar`, and `tabbar` pages are not cached. It uses the `tabbar` component of a third-party UI library.
  - Pros: any svg icon can be configured, switching font colors is easy, and fancy animations are possible.
  - Cons: the `tabbar` flickers on the first click, and there is no cache.


> Note: fancy effects need to be implemented yourself; this template does not provide them.
