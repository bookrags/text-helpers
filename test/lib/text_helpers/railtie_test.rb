require_relative '../../test_helper'

require 'active_support'
require 'rails'
require 'rails/railtie'
require 'rails/application'
require 'text_helpers/railtie'

describe TextHelpers::Railtie do
  include StubHelpers

  let(:railtie) { TextHelpers::Railtie }
  let(:action_view_base) { Class.new }
  let(:action_mailer_base) { Class.new }
  let(:action_controller_base) { Class.new }

  let(:app) do
    # Ref: https://github.com/rails/rails/issues/42319
    # ref: https://github.com/getsentry/sentry-ruby/commit/e21fac946b3d2d03ff11aae86a98a49f42054df9#diff-18f3f95d0126b5b677a9472bd8f57b4123fdfbb3412f5762ebf1d5667ad67b7bR92
    ActiveSupport::Dependencies.autoload_once_paths = []
    ActiveSupport::Dependencies.autoload_paths = []
    Class.new(Rails::Application) do
      config.eager_load = false

      self
    end
  end

  let(:stub_resets) do
    []
  end

  before do
    stub_resets << stub_nested_const(TextHelpers::Railtie, "ActionView::Base", action_view_base)
    stub_resets << stub_nested_const(TextHelpers::Railtie, "ActionMailer::Base", action_mailer_base)
    stub_resets << stub_nested_const(TextHelpers::Railtie, "ActionController::Base", action_controller_base)
    app.initialize!
  end

  after do
    stub_resets.reverse.map(&:call)
  end

  describe "ActionView::Base extensions" do
    it "includes TextHelpers::Translation" do
      assert_includes(action_view_base.included_modules, TextHelpers::Translation)
    end

    describe "#translation_scope" do
      let(:action_view_base) do
        Class.new do
          attr_accessor :virtual_path, :params
        end
      end

      let(:view_instance) { action_view_base.new }

      it "is based on the view virtual path if a matching path is present" do
        view_instance.virtual_path = 'foo/bar/_some_view.html.haml'
        assert_equal('views.foo.bar.some_view', view_instance.translation_scope)
      end

      it "is based on the controller and action name with a non-matching virtual path" do
        view_instance.virtual_path = 'this-wont-match-at-all'
        view_instance.params = {controller: "a_controller", action: "an_action"}
        assert_equal('views.a_controller.an_action', view_instance.translation_scope)
      end

      it "is based on the controller and action name with no virtual path" do
        view_instance.virtual_path = nil
        view_instance.params = {controller: "a_controller", action: "an_action"}
        assert_equal('views.a_controller.an_action', view_instance.translation_scope)
      end
    end
  end

  describe "ActionMailer::Base extensions" do
    it "includes TextHelpers::Translation" do
      assert_includes(action_mailer_base.included_modules, TextHelpers::Translation)
    end

    describe "#translation_scope" do
      let(:action_mailer_base) do
        Class.new do
          attr_accessor :mailer_name, :action_name
        end
      end

      let(:mailer_instance) { action_mailer_base.new }

      it "is based on the mailer name and action" do
        mailer_instance.mailer_name = "foo/bar/baz_mailer"
        mailer_instance.action_name = "notification_message"
        assert_equal('mailers.foo.bar.baz.notification_message', mailer_instance.translation_scope)
      end
    end
  end

  describe "ActionController::Base extensions" do
    it "includes TextHelpers::Translation" do
      assert_includes(action_mailer_base.included_modules, TextHelpers::Translation)
    end

    describe "#translation_scope" do
      let(:action_mailer_base) do
        Class.new do
          attr_accessor :mailer_name, :action_name
        end
      end

      let(:mailer_instance) { action_mailer_base.new }

      it "is based on the mailer name and action" do
        mailer_instance.mailer_name = "foo/bar/baz_mailer"
        mailer_instance.action_name = "notification_message"
        assert_equal('mailers.foo.bar.baz.notification_message', mailer_instance.translation_scope)
      end
    end
  end
end
