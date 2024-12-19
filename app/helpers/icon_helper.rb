module IconHelper
  def render_icon(name, options = {})
    options[:class] = Array.wrap(options[:class])

    case name.to_sym
    when :plus
      render_plus_icon(options)
    when :sun
      render_sun_icon(options)
    when :moon
      render_moon_icon(options)
    when :magnifying_glass
      render_magnifying_glass_icon(options)
    when :x_mark
      render_x_mark_icon(options)
    when :video_camera
      render_video_camera_icon(options)
    when :eye
      render_eye_icon(options)
    when :calendar
      render_calendar_icon(options)
    when :link
      render_link_icon(options)
    when :video
      render_video_icon(options)
    when :channel
      render_channel_icon(options)
    when :cog
      render_cog_icon(options)
    when :bars_3
      render_bars_3_icon(options)
    when :heart
      render_heart_icon(options)
    when :share
      render_share_icon(options)
    when :clipboard
      render_clipboard_icon(options)
    when :arrow_down
      render_arrow_down_icon(options)
    else
      raise ArgumentError, "Unknown icon: #{name}"
    end
  end

  private

  def render_plus_icon(options)
    tag.svg xmlns: "http://www.w3.org/2000/svg", fill: "none", viewBox: "0 0 24 24", stroke_width: "1.5", stroke: "currentColor", **options do
      tag.path stroke_linecap: "round", stroke_linejoin: "round", d: "M12 4.5v15m7.5-7.5h-15"
    end
  end

  def render_sun_icon(options)
    tag.svg xmlns: "http://www.w3.org/2000/svg", fill: "none", viewBox: "0 0 24 24", stroke_width: "1.5", stroke: "currentColor", **options do
      tag.path stroke_linecap: "round", stroke_linejoin: "round", d: "M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707M16 12a4 4 0 11-8 0 4 4 0 018 0z"
    end
  end

  def render_moon_icon(options)
    tag.svg xmlns: "http://www.w3.org/2000/svg", fill: "none", viewBox: "0 0 24 24", stroke_width: "1.5", stroke: "currentColor", **options do
      tag.path stroke_linecap: "round", stroke_linejoin: "round", d: "M21.752 15.002A9.718 9.718 0 0118 15.75c-5.385 0-9.75-4.365-9.75-9.75 0-1.33.266-2.597.748-3.752A9.753 9.753 0 003 11.25C3 16.635 7.365 21 12.75 21a9.753 9.753 0 009.002-5.998z"
    end
  end

  def render_magnifying_glass_icon(options)
    tag.svg xmlns: "http://www.w3.org/2000/svg", fill: "none", viewBox: "0 0 24 24", stroke_width: "1.5", stroke: "currentColor", **options do
      tag.path stroke_linecap: "round", stroke_linejoin: "round", d: "M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"
    end
  end

  def render_x_mark_icon(options)
    tag.svg xmlns: "http://www.w3.org/2000/svg", fill: "none", viewBox: "0 0 24 24", stroke_width: "1.5", stroke: "currentColor", **options do
      tag.path stroke_linecap: "round", stroke_linejoin: "round", d: "M6 18L18 6M6 6l12 12"
    end
  end

  def render_video_camera_icon(options)
    tag.svg xmlns: "http://www.w3.org/2000/svg", fill: "none", viewBox: "0 0 24 24", stroke_width: "1.5", stroke: "currentColor", **options do
      tag.path stroke_linecap: "round", stroke_linejoin: "round", d: "M15.75 10.5l4.72-4.72a.75.75 0 011.28.53v11.38a.75.75 0 01-1.28.53l-4.72-4.72M4.5 18.75h9a2.25 2.25 0 002.25-2.25v-9a2.25 2.25 0 00-2.25-2.25h-9A2.25 2.25 0 002.25 7.5v9a2.25 2.25 0 002.25 2.25z"
    end
  end

  def render_eye_icon(options)
    tag.svg xmlns: "http://www.w3.org/2000/svg", fill: "none", viewBox: "0 0 24 24", stroke_width: "1.5", stroke: "currentColor", **options do
      safe_join([
        tag.path(stroke_linecap: "round", stroke_linejoin: "round", d: "M2.036 12.322a1.012 1.012 0 010-.639C3.423 7.51 7.36 4.5 12 4.5c4.638 0 8.573 3.007 9.963 7.178.07.207.07.431 0 .639C20.577 16.49 16.64 19.5 12 19.5c-4.638 0-8.573-3.007-9.963-7.178z"),
        tag.path(stroke_linecap: "round", stroke_linejoin: "round", d: "M15 12a3 3 0 11-6 0 3 3 0 016 0z")
      ])
    end
  end

  def render_calendar_icon(options)
    tag.svg xmlns: "http://www.w3.org/2000/svg", fill: "none", viewBox: "0 0 24 24", stroke_width: "1.5", stroke: "currentColor", **options do
      tag.path stroke_linecap: "round", stroke_linejoin: "round", d: "M6.75 3v2.25M17.25 3v2.25M3 18.75V7.5a2.25 2.25 0 012.25-2.25h13.5A2.25 2.25 0 0121 7.5v11.25m-18 0A2.25 2.25 0 005.25 21h13.5A2.25 2.25 0 0021 18.75m-18 0v-7.5A2.25 2.25 0 015.25 9h13.5A2.25 2.25 0 0121 11.25v7.5"
    end
  end

  def render_link_icon(options)
    tag.svg xmlns: "http://www.w3.org/2000/svg", fill: "none", viewBox: "0 0 24 24", stroke_width: "1.5", stroke: "currentColor", **options do
      tag.path stroke_linecap: "round", stroke_linejoin: "round", d: "M13.19 8.688a4.5 4.5 0 011.242 7.244l-4.5 4.5a4.5 4.5 0 01-6.364-6.364l1.757-1.757m13.35-.622l1.757-1.757a4.5 4.5 0 00-6.364-6.364l-4.5 4.5a4.5 4.5 0 001.242 7.244"
    end
  end

  def render_video_icon(options)
    tag.svg xmlns: "http://www.w3.org/2000/svg", fill: "none", viewBox: "0 0 24 24", stroke_width: "1.5", stroke: "currentColor", **options do
      safe_join([
        tag.path(stroke_linecap: "round", stroke_linejoin: "round", d: "M21 12a9 9 0 11-18 0 9 9 0 0118 0z"),
        tag.path(stroke_linecap: "round", stroke_linejoin: "round", d: "M15.91 11.672a.375.375 0 010 .656l-5.603 3.113a.375.375 0 01-.557-.328V8.887c0-.286.307-.466.557-.327l5.603 3.112z")
      ])
    end
  end

  def render_channel_icon(options)
    tag.svg xmlns: "http://www.w3.org/2000/svg", fill: "none", viewBox: "0 0 24 24", stroke_width: "1.5", stroke: "currentColor", **options do
      tag.path stroke_linecap: "round", stroke_linejoin: "round", d: "M6 13.5V3.75m0 9.75a1.5 1.5 0 010 3m0-3a1.5 1.5 0 000 3m0 3.75V16.5m12-3V3.75m0 9.75a1.5 1.5 0 010 3m0-3a1.5 1.5 0 000 3m0 3.75V16.5m-6-9V3.75m0 3.75a1.5 1.5 0 010 3m0-3a1.5 1.5 0 000 3m0 9.75V10.5"
    end
  end

  def render_cog_icon(options)
    tag.svg xmlns: "http://www.w3.org/2000/svg", fill: "none", viewBox: "0 0 24 24", stroke_width: "1.5", stroke: "currentColor", **options do
      safe_join([
        tag.path(stroke_linecap: "round", stroke_linejoin: "round", d: "M9.594 3.94c.09-.542.56-.94 1.11-.94h2.593c.55 0 1.02.398 1.11.94l.213 1.281c.063.374.313.686.645.87.074.04.147.083.22.127.324.196.72.257 1.075.124l1.217-.456a1.125 1.125 0 011.37.49l1.296 2.247a1.125 1.125 0 01-.26 1.431l-1.003.827c-.293.24-.438.613-.431.992a6.759 6.759 0 010 .255c-.007.378.138.75.43.99l1.005.828c.424.35.534.954.26 1.43l-1.298 2.247a1.125 1.125 0 01-1.369.491l-1.217-.456c-.355-.133-.75-.072-1.076.124a6.57 6.57 0 01-.22.128c-.331.183-.581.495-.644.869l-.213 1.28c-.09.543-.56.941-1.11.941h-2.594c-.55 0-1.02-.398-1.11-.94l-.213-1.281c-.062-.374-.312-.686-.644-.87a6.52 6.52 0 01-.22-.127c-.325-.196-.72-.257-1.076-.124l-1.217.456a1.125 1.125 0 01-1.369-.49l-1.297-2.247a1.125 1.125 0 01.26-1.431l1.004-.827c.292-.24.437-.613.43-.992a6.932 6.932 0 010-.255c.007-.378-.138-.75-.43-.99l-1.004-.828a1.125 1.125 0 01-.26-1.43l1.297-2.247a1.125 1.125 0 011.37-.491l1.216.456c.356.133.751.072 1.076-.124.072-.044.146-.087.22-.128.332-.183.582-.495.644-.869l.214-1.281z"),
        tag.path(stroke_linecap: "round", stroke_linejoin: "round", d: "M15 12a3 3 0 11-6 0 3 3 0 016 0z")
      ])
    end
  end

  def render_bars_3_icon(options)
    tag.svg xmlns: "http://www.w3.org/2000/svg", fill: "none", viewBox: "0 0 24 24", stroke_width: "1.5", stroke: "currentColor", **options do
      tag.path stroke_linecap: "round", stroke_linejoin: "round", d: "M3.75 6.75h16.5M3.75 12h16.5m-16.5 5.25h16.5"
    end
  end

  def render_heart_icon(options)
    tag.svg xmlns: "http://www.w3.org/2000/svg", fill: "none", viewBox: "0 0 24 24", stroke_width: "1.5", stroke: "currentColor", **options do
      tag.path stroke_linecap: "round", stroke_linejoin: "round", d: "M21 8.25c0-2.485-2.099-4.5-4.688-4.5-1.935 0-3.597 1.126-4.312 2.733-.715-1.607-2.377-2.733-4.313-2.733C5.1 3.75 3 5.765 3 8.25c0 7.22 9 12 9 12s9-4.78 9-12z"
    end
  end

  def render_share_icon(options)
    tag.svg xmlns: "http://www.w3.org/2000/svg", fill: "none", viewBox: "0 0 24 24", stroke_width: "1.5", stroke: "currentColor", **options do
      tag.path stroke_linecap: "round", stroke_linejoin: "round", d: "M7.217 10.907a2.25 2.25 0 100 2.186m0-2.186c.18.324.283.696.283 1.093s-.103.77-.283 1.093m0-2.186l9.566-5.314m-9.566 7.5l9.566 5.314m0 0a2.25 2.25 0 103.935 2.186 2.25 2.25 0 00-3.935-2.186zm0-12.814a2.25 2.25 0 103.933-2.185 2.25 2.25 0 00-3.933 2.185z"
    end
  end

  def render_clipboard_icon(options)
    tag.svg xmlns: "http://www.w3.org/2000/svg", fill: "none", viewBox: "0 0 24 24", stroke_width: "1.5", stroke: "currentColor", **options do
      tag.path stroke_linecap: "round", stroke_linejoin: "round", d: "M15.666 3.888A2.25 2.25 0 0013.5 2.25h-3c-1.03 0-1.9.693-2.166 1.638m7.332 0c.055.194.084.4.084.612v0a.75.75 0 01-.75.75H9a.75.75 0 01-.75-.75v0c0-.212.03-.418.084-.612m7.332 0c.646.049 1.288.11 1.927.184 1.1.128 1.907 1.077 1.907 2.185V19.5a2.25 2.25 0 01-2.25 2.25H6.75A2.25 2.25 0 014.5 19.5V6.257c0-1.108.806-2.057 1.907-2.185a48.208 48.208 0 011.927-.184"
    end
  end

  def render_arrow_down_icon(options)
    tag.svg xmlns: "http://www.w3.org/2000/svg", fill: "none", viewBox: "0 0 24 24", stroke_width: "1.5", stroke: "currentColor", **options do
      tag.path stroke_linecap: "round", stroke_linejoin: "round", d: "M3 16.5v2.25A2.25 2.25 0 005.25 21h13.5A2.25 2.25 0 0021 18.75V16.5M16.5 12L12 16.5m0 0L7.5 12m4.5 4.5V3"
    end
  end
end
