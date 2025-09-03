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
│   │   - Uses remove_item_controller.js for smooth removal with permanent deleted state
│   │   - Shows blurred state with overlay that persists until page refresh
│   │
│   └── show.html.erb
│       - Subscribes to Turbo Streams via `<%= turbo_stream_from "summaries:#{@summary_data[:video_id]}" %>`
│       - Uses Rails forms with Turbo Streams for audio generation (no JavaScript controller needed)
│       └── Partials:
│           ├── shared/_container
│           ├── shared/_video_player
│           ├── _audio_summary_section (SIMPLIFIED - now uses Rails forms with Turbo Stream updates)
│           ├── _audio_generating_state (loading state for audio generation)
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
│   │   - Uses remove_item_controller.js for smooth removal with permanent deleted state
│   │   - Shows blurred state with overlay that persists until page refresh
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
│       - `_demo_transcript_section.html.erb`: Transcript with proper segment structure and download functionality
│
├── 📧 mailers/
│   ├── user_mailer/
│   │   ├── email_verification.html.erb
│   │   └── password_reset.html.erb
│   │
│   └── passwords_mailer/
│       ├── reset.html.erb
│       └── reset.text.erb
│
├── 🔐 authentication/
│   ├── sessions/
│   │   └── new.html.erb
│   │       └── Partials:
│   │           ├── shared/_auth_layout
│   │           ├── shared/_form_components/auth_input
│   │           └── shared/_form_components/button
│   │
│   ├── registrations/
│   │   └── new.html.erb
│   │       └── Partials:
│   │           ├── shared/_auth_layout
│   │           ├── shared/_form_components/auth_input
│   │           └── shared/_form_components/button
│   │
│   └── passwords/
│       ├── new.html.erb
│       └── edit.html.erb
│           └── Partials:
│               ├── shared/_auth_layout
│               ├── shared/_form_components/auth_input
│               └── shared/_form_components/button
│
├── ⚙️ settings/
│   └── index.html.erb
│       └── Partials:
│           ├── shared/_container
│           ├── shared/_section
│           └── shared/_form_components/button
│
├── 📄 pages/
│   ├── about.html.erb
│   │   └── Partials:
│   │       ├── shared/_container
│   │       ├── shared/_page_header
│   │       └── pages/about/_description
│   │
│   ├── contact.html.erb
│   │   └── Partials:
│   │       ├── shared/_container
│   │       ├── shared/_page_header
│   │       └── pages/contact/_description
│   │
│   └── discover.html.erb
│       └── Partials:
│           ├── shared/_container
│           ├── shared/_page_header
│           ├── shared/_grid
│           ├── shared/_video_card
│           └── pages/discover/_content
│
├── 🚀 pwa/
│   ├── manifest.json.erb
│   └── service-worker.js
│
└── 🔧 shared/
    ├── _action_buttons.html.erb
    ├── _auth_input.html.erb
    ├── _auth_layout.html.erb
    ├── _card_skeleton.html.erb
    ├── _card.html.erb
    ├── _centered_search_layout.html.erb
    ├── _channel_about.html.erb
    ├── _channel_card.html.erb
    ├── _container.html.erb
    ├── _empty_state.html.erb
    ├── _error_message.html.erb
    ├── _flash_message.html.erb
    ├── _footer_links.html.erb
    ├── _footer.html.erb
    ├── _grid.html.erb
    ├── _head.html.erb
    ├── _image.html.erb
    ├── _layout.html.erb
    ├── _loading_context.html.erb
    ├── _nav_links.html.erb
    ├── _nav.html.erb
    ├── _page_header.html.erb
    ├── _pagination.html.erb
    ├── _search_form.html.erb
    ├── _search_results.html.erb
    ├── _section.html.erb
    ├── _sidebar.html.erb
    ├── _skeleton.html.erb
    ├── _spinner.html.erb
    ├── _static_page.html.erb
    ├── _teaser.html.erb
    ├── _toast.html.erb
    ├── _truncate.html.erb
    ├── _user_switcher.html.erb
    ├── _video_card.html.erb
    ├── _video_grid.html.erb
    └── form_components/
        ├── _auth_input.html.erb
        ├── _button.html.erb
        ├── _input.html.erb
        ├── _search_input.html.erb
        └── _url_input.html.erb

## Data Storage Architecture Updates

The application now uses a standardized MongoDB-based data persistence approach:

- **Persistable Concern** - Unified data storage interface with consistent API across all services
- **Standardized Methods** - All services use `fetch_stored`, `write_stored`, `read_stored`, `stored?`, `delete_stored`
- **Enhanced Error Handling** - Improved retry mechanism and graceful failure handling
- **Namespace Support** - Flexible namespace management with service-specific defaults
- **Force Execution** - Ability to bypass storage and regenerate data when needed
- **Clear Naming** - Renamed from "cache" terminology to "storage" to reflect MongoDB as primary data store

## Key View Features

1. **Turbo Streams Integration** - Real-time updates via ActionCable
2. **Responsive Design** - Mobile-friendly with Tailwind CSS
3. **Dark/Light Mode** - Consistent theming across all components
4. **Modular Partials** - Reusable components for maintainability
5. **Form Components** - Consistent input styling and behavior
6. **Loading States** - Skeleton loaders and spinners for better UX
7. **Error Handling** - Graceful error display and recovery
8. **Accessibility** - Proper ARIA labels and keyboard navigation
9. **Turbo Stream Consistency** - All AJAX-like interactions use Turbo Streams instead of JSON
10. **Audio Generation Simplification** - (NEW) Replaced JavaScript controller with Rails forms for better Rails 8 integration

## JavaScript Controllers

- **Theme Controller** - Dark/light mode switching
- **Copy Controller** - Text copying functionality
- **Toast Controller** - Notification system
- **Loading Controller** - Loading state management
- **Search Controller** - Search functionality
- **Tabs Controller** - Tab switching behavior
- **Remove Item Controller** - Item removal with confirmation
- **Email Reveal Controller** - Email address protection
- **Nav Toggle Controller** - Mobile navigation
- **Dropdown Controller** - Dropdown menu functionality
- **❌ REMOVED - Audio Controller** - Simplified to use Rails forms with Turbo Streams (no JavaScript needed)
