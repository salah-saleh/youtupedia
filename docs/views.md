📁 views/
├── 🌐 layouts/
│   ├── application.html.erb
│   │   └── Partials:
│   │       ├── shared/_navbar
│   │       └── shared/_flash
│   │
│   └── dashboard.html.erb
│       └── Partials:
│           └── shared/_layout
│
├── 🎥 summaries/
│   ├── index.html.erb
│   │   └── Partials:
│   │       ├── shared/_form_section
│   │       ├── shared/_form_components/url_input
│   │       ├── shared/_form_components/button
│   │       ├── shared/_page_header
│   │       ├── shared/_grid
│   │       ├── shared/_video_card (with remove button support)
│   │       └── shared/_empty_state
│   │   Notes:
│   │   - Video cards include remove buttons when show_remove_button: true
│   │   - Uses remove_item_controller.js for AJAX removal
│   │
│   └── show.html.erb
│       - Subscribes to Turbo Streams via `<%= turbo_stream_from "summaries:#{@summary_data[:video_id]}" %>`
│       └── Partials:
│           ├── shared/_container
│           ├── shared/_video_player
│           ├── shared/_summary_section
│           ├── shared/_takeaways
│           ├── shared/_transcript
│           ├── shared/_chat_section
│           ├── shared/_loading_state
│           └── shared/_error_state
│
├── 📺 channels/
│   ├── index.html.erb
│   │   └── Partials:
│   │       ├── shared/_form_section
│   │       ├── shared/_form_components/url_input
│   │       ├── shared/_form_components/button
│   │       ├── shared/_page_header
│   │       ├── shared/_grid
│   │       ├── shared/_channel_card (with remove button support)
│   │       └── shared/_empty_state
│   │   Notes:
│   │   - Channel cards include remove buttons when show_remove_button: true
│   │   - Uses remove_item_controller.js for AJAX removal
│   │
│   └── show.html.erb
│       └── Partials:
│           ├── shared/_icon
│           └── shared/_container
│       Notes:
│       - Includes a search bar (same style as channels/index) to search within the channel by title/description.
│       - When `q` is present, the grid results come from `search.list` scoped to the channel and sorted by relevance.
│       Notes:
│       - Uses `shared/_video_grid` with `youtube_pagination: true`.
│       - Pagination controls (`shared/_pagination`) now rely on `@next_token` / `@prev_token` coming from `playlistItems.list` via the uploads playlist, ensuring tokens are present when more pages exist.
│
├── 🔍 search/index.html.erb
│   └── Partials:
│       ├── shared/_form_section
│       ├── shared/_form_components/search_input
│       ├── shared/_form_components/button
│       ├── shared/_section
│       └── shared/_video_grid
│
├── 🏠 home/
│   │
│   ├── demo/
│   │   ├── _summary_section.html.erb (TL;DR and Details tabs)
│   │   ├── _timeline_section.html.erb (Timeline tab with copy and download functionality)
│   │   └── _transcript_section.html.erb (Transcript tab with copy and download functionality)
│   │
│   └── index.html.erb
│       └── Partials:
│           ├── shared/_teaser (feature teaser section under the search)
│           ├── home/_demo_summary (static demo card styled like summaries/show)
│           │   └── Sub-partials:
│           │       ├── home/demo/_summary_section
│           │       ├── home/demo/_timeline_section
│           │       └── home/demo/_transcript_section
│           └── shared/_nav_links (via layout)
│
│   Notes (2025-08-12):
│   - Background moved to layout: mesh gradient + geometric grid overlay now applied globally via `shared/_layout`.
│   - `home/_demo_summary` updates:
│     - Demo title hover no longer underlines; now slightly increases weight for emphasis.
│     - Inside the Summary tab, TL;DR now appears above Details.
│     - Right-hand tab content uses a non-sticky tab row and scrollable panels that fill the available height, constrained by a max card height of 950px.
│     - Copy and download functionality now matches `summaries/show.html.erb` behavior:
│       - Timeline: Individual copy buttons for each item using `data-copy-single-target`
│       - Transcript: Proper segment structure with `data-youtube-target="segment"` and download functionality
│       - All sections use consistent `data-copy-target="button"` and `data-copy-target="source"` structure
│     - Modular structure: Broken down into smaller partials for better maintainability:
│       - `_demo_summary_section.html.erb`: TL;DR and Details sections with copy/download functionality
│       - `_demo_timeline_section.html.erb`: Timeline with individual item copy buttons and proper data structure
│       - `_demo_transcript_section.html.erb`: Transcript with segmented content and download functionality
│
├── ⚙️ settings/index.html.erb
│   └── Partials:
│       ├── shared/_section
│       ├── shared/_icon
│       ├── shared/_form_components/button
│       └── shared/_user_switcher
│
├── 🔐 auth/
│   ├── passwords/
│   │   ├── edit.html.erb
│   │   │   └── Partials:
│   │   │       └── shared/_container
│   │   │
│   │   └── new.html.erb
│   │       └── Partials:
│   │           └── shared/_container
│   │
│   ├── registrations/new.html.erb
│   │   └── Partials:
│   │       └── shared/_container
│   │
│   └── sessions/new.html.erb
│       └── Partials:
│           └── shared/_container
│
└── 🛠️ dev/users/
    ├── index.html.erb
    │   └── Partials:
    │       └── shared/_user_switcher
    │
    └── new.html.erb
        └── Partials:
            └── shared/_container

📊 Shared Partial Usage Frequency:
1. _container.html.erb (7 uses)
   - All auth views
   - dev/users/new
   - channels/show
   - summaries/show

2. _form_components/* (Multiple uses)
   - button (5 uses)
   - url_input (2 uses)
   - search_input (1 use)

3. _section.html.erb (2 uses)
   - search/index
   - settings/index

4. _user_switcher.html.erb (2 uses)
   - settings/index
   - dev/users/index

5. _empty_state.html.erb (2 uses)
   - summaries/index
   - channels/index

6. _grid.html.erb (2 uses)
   - summaries/index
   - channels/index

7. New Summary-specific components (1 use each)
   - _video_player
   - _summary_section
   - _takeaways
   - _transcript
   - _chat_section
   - _loading_state
   - _error_state

Styling consistency (2025-08-10):
- Summary page sections (`_tldr_section`, `_summary_section`, `_transcript_section`) now share the same container styles:
  - `bg-gray-100 dark:bg-gray-900 rounded-lg shadow p-4 lg:p-6 border border-gray-200 dark:border-gray-700`
  - Ensures parity between light/dark modes and consistent padding/borders.
- Copy icons updated to use neutral colors: `text-gray-600 dark:text-gray-300 hover:text-gray-800 dark:hover:text-gray-100` across all sections for visual consistency.

🔄 Controller Relationships for summaries/show:
- youtube_controller.js: Controls video player functionality
- loading_message_controller.js: Handles loading message in TLDR until content arrives
- timeline_controller.js: Handles transcript/takeaways interactions
- (Removed) summary_loader_controller.js (replaced by server-pushed Turbo Streams)

Transcript Section (downloads) (2025-08-10)
- Added download buttons for full and segmented transcripts in `summaries/show/_transcript_section.html.erb`.
- Uses Stimulus controller `summaries/transcript_download_controller.js` wired via `data-controller="transcript-download"`.
- Values passed:
  - `data-transcript-download-full-value`: full transcript text used for the Full download (falls back to DOM if missing)
  - `data-transcript-download-video-id-value`: used to generate file names (sourced from `summary[:video_id]`)
- Buttons trigger actions:
  - `transcript-download#downloadFull`
  - `transcript-download#downloadSegmented`

Note on Turbo Streams rendering (2025-08-13)
- Sections updated over websockets are rendered via server-pushed Turbo Streams with `locals: { summary: payload }`.
- Therefore, section partials like `_tldr_section`, `_summary_section`, `_transcript_section`, `_takeaways_section`, and `_chat_section` must exclusively reference the `summary` local (e.g., `summary[:video_id]`) and not controller instance variables such as `@summary_data`.

💡 Additional Recommendations:
1. Consider standardizing error and loading states across all views
2. Look for opportunities to reuse summary-specific components in other views
3. Review if some summary partials could be generalized for broader use
4. Consider standardizing home views to use shared components
5. Look for opportunities to extract common patterns in home views into shared partials
6. Consider creating a shared form layout since many views use similar form structures
7. Review if some partials could be combined (e.g., _grid and _video_grid)

🔧 JavaScript Controllers:
├── shared/
│   ├── remove_item_controller.js - Handles smooth animations when removing summaries and channels
│   │   └── Features:
│   │       ├── Smooth fade-out animations before Turbo Stream removal
│   │       ├── Loading states with spinner
│   │       ├── Empty state handling
│   │       ├── Error handling with user feedback
│   │       └── CSRF token support for Rails security
│   │   └── Usage:
│   │       ├── Video cards: data-controller="remove-item" data-remove-item-type-value="summary" data-remove-item-id-value="..."
│   │       └── Channel cards: data-controller="remove-item" data-remove-item-type-value="channel" data-remove-item-id-value="..."
│   │   └── Architecture:
│   │       ├── JavaScript handles animations only
│   │       └── Turbo Streams handle actual DOM removal
│   │
│   ├── toast_controller.js - Displays toast notifications
│   ├── theme_controller.js - Handles light/dark mode switching
│   └── copy_controller.js - Handles copy-to-clipboard functionality
│
├── summaries/
│   ├── youtube_controller.js - Controls video player functionality
│   ├── loading_message_controller.js - Handles loading message in TLDR until content arrives
│   ├── timeline_controller.js - Handles transcript/takeaways interactions
│   └── transcript_download_controller.js - Handles transcript download functionality
│
└── home/
    └── search_animation_controller.js - Handles search animation effects
