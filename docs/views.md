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
│   │       ├── shared/_video_card
│   │       └── shared/_empty_state
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
│   │       ├── shared/_channel_card
│   │       └── shared/_empty_state
│   │
│   └── show.html.erb
│       └── Partials:
│           ├── shared/_icon
│           └── shared/_container
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
│   └── index.html.erb
│       └── No shared partials. Redirects to summaries index page for signed in users. Otherwise, redirects to new_session_path.
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

🔄 Controller Relationships for summaries/show:
- youtube_controller.js: Controls video player functionality
- loading_message_controller.js: Handles loading message in TLDR until content arrives
- timeline_controller.js: Handles transcript/takeaways interactions
- (Removed) summary_loader_controller.js (replaced by server-pushed Turbo Streams)

💡 Additional Recommendations:
1. Consider standardizing error and loading states across all views
2. Look for opportunities to reuse summary-specific components in other views
3. Review if some summary partials could be generalized for broader use
4. Consider standardizing home views to use shared components
5. Look for opportunities to extract common patterns in home views into shared partials
6. Consider creating a shared form layout since many views use similar form structures
7. Review if some partials could be combined (e.g., _grid and _video_grid)
