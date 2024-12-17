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
│   ├── _landing_page.html.erb
│   │   └── No shared partials
│   │
│   └── index.html.erb
│       └── No shared partials
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
- chat_controller.js: Manages AI chat interactions
- loading_controller.js: Handles loading states
- summary_loader_controller.js: Manages summary generation process
- collapsible_controller.js: Handles expandable sections
- copy_controller.js: Manages copy functionality for summary content

💡 Additional Recommendations:
1. Consider standardizing error and loading states across all views
2. Look for opportunities to reuse summary-specific components in other views
3. Review if some summary partials could be generalized for broader use
4. Consider standardizing home views to use shared components
5. Look for opportunities to extract common patterns in home views into shared partials
6. Consider creating a shared form layout since many views use similar form structures
7. Review if some partials could be combined (e.g., _grid and _video_grid)
