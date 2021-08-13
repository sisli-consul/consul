module Consul
  class Application < Rails::Application
    unless Rails.env.test?
      config.i18n.default_locale = :tr
      config.i18n.available_locales = [:tr, :en]
      config.i18n.enforce_available_locales = false
      config.i18n.fallbacks = { tr: :en }
    end
  end
end
