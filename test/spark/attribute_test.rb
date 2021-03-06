# frozen_string_literal: true

require "test_helper"
require "spark/component/attribute"

module Spark
  module Component
    class AttributeTest < Minitest::Test
      parallelize_me!

      def base_class
        Class.new do
          include ActiveModel::Validations
          include Attribute

          def initialize(attributes = nil)
            initialize_attributes(attributes)
          end

          # To ensure activemodel tests class
          def self.name
            "TestClass"
          end
        end.dup
      end

      def test_has_default_attributes
        expected = { id: nil, class: nil, data: nil, aria: nil, html: nil }
        assert_equal(expected, base_class.attributes)
      end

      def test_can_add_to_attributes
        klass = base_class
        klass.attribute :foo

        assert_includes klass.attributes.keys, :foo
      end

      def test_can_attributes_with_defaults
        klass = base_class
        klass.attribute :foo, bar: :baz

        assert_includes klass.attributes.keys, :foo
        assert_equal :baz, klass.attributes[:bar]
      end

      def test_can_set_initialize_attributes
        klass = base_class
        klass.attribute :foo, bar: :baz

        klass_instance = klass.new(foo: "filled")
        assert_equal("filled", klass_instance.attribute(:foo))
        assert_equal(:baz, klass_instance.attribute(:bar))
        assert_equal({ foo: "filled", bar: :baz }, klass_instance.attributes)
      end

      def test_ignores_undefined_attributes
        klass = base_class
        klass.attribute foo: :bar

        klass_instance = klass.new(test: true)
        assert_equal({ foo: :bar }, klass_instance.attributes)
      end

      def test_includes_base_attributes
        attrs = {
          id: "foo", class: "bar",
          data: { baz: true },
          aria: { label: "test" },
          html: { role: "button" }
        }

        klass_instance = base_class.new(**attrs)
        assert_equal(attrs, klass_instance.attributes)
      end

      # Ensure that attr_hash returns values for present attributes
      # and does not return keys with nil or empty values
      def test_attr_hash
        klass = base_class
        klass.attribute :a, b: true

        klass_instance = klass.new(a: 1)
        assert_equal({ a: 1, b: "true" }, klass_instance.attr_hash(:a, :b, :c, :id, :data))
      end

      def test_base_attrs_assignable_by_attributes
        klass = base_class

        attrs = {
          aria: { label: "test" },
          data: { some_data: true },
          id: "foo", class: %w[bar baz],
          html: { role: "button" }
        }

        klass_instance = klass.new(**attrs)
        assert_equal({ "some-data" => true }, klass_instance.data)
        assert_equal({ label: "test" }, klass_instance.aria)
        assert_equal(%w[bar baz], klass_instance.classname)

        tag_attrs = {
          aria: { label: "test" },
          data: { "some-data" => true },
          class: %w[bar baz],
          id: "foo", role: "button"
        }

        assert_equal(tag_attrs, klass_instance.tag_attrs)
      end

      def test_tag_attributes_injects_arguments_into_tag_attrs
        klass = base_class
        klass.tag_attribute(:foo, bar: true)

        klass_instance = klass.new(
          foo: "hi",
          bar: false
        )

        tag_attrs = {
          foo: "hi",
          bar: false
        }

        assert_equal(tag_attrs, klass_instance.tag_attrs)
      end

      def test_tag_attributes_supports_data_key
        klass = base_class
        klass.tag_attribute(data: { foo: nil, bar: true })

        assert_equal({ data: { bar: "true" } }, klass.new.tag_attrs)

        klass_instance = klass.new(foo: "hi", bar: false)
        tag_attrs = { data: { foo: "hi", bar: false } }

        assert_equal(tag_attrs, klass_instance.tag_attrs)
      end

      def test_data_attributes_injects_arguments_into_tag_attrs
        klass = base_class
        klass.data_attribute(:foo, bar: true)

        assert_equal({ data: { bar: "true" } }, klass.new.tag_attrs)

        klass_instance = klass.new(foo: "hi", bar: false)
        tag_attrs = { data: { foo: "hi", bar: false } }

        assert_equal(tag_attrs, klass_instance.tag_attrs)
      end

      def test_tag_attributes_supports_aria_key
        klass = base_class
        klass.tag_attribute(aria: { foo: nil, bar: true })

        assert_equal({ aria: { bar: "true" } }, klass.new.tag_attrs)

        klass_instance = klass.new(foo: "hi", bar: false)
        tag_attrs = { aria: { foo: "hi", bar: false } }

        assert_equal(tag_attrs, klass_instance.tag_attrs)
      end

      def test_aria_attributes_injects_arguments_into_tag_attrs
        klass = base_class
        klass.aria_attribute(:foo, bar: true)

        assert_equal({ aria: { bar: "true" } }, klass.new.tag_attrs)

        klass_instance = klass.new(foo: "hi", bar: false)
        tag_attrs = { aria: { foo: "hi", bar: false } }

        assert_equal(tag_attrs, klass_instance.tag_attrs)
      end

      def test_attribute_default_group_assigns_defaults
        klass = base_class
        klass.attribute bar: "toast", theme: :a

        klass.attribute_default_group(theme: {
                                        a: { bar: true, baz: false },
                                        b: { baz: true }
                                      })

        expected = { bar: "true", theme: :a }
        assert_equal expected, klass.new.attributes

        klass_instance = klass.new(theme: :b)
        expected = { bar: "toast", theme: :b }
        assert_equal expected, klass_instance.attributes
        assert_equal true, klass_instance.instance_variable_get(:"@baz")
      end

      def test_attribute_default_group_with_boolean_keys
        klass = base_class
        klass.attribute :foo

        klass.attribute_default_group(foo: {
                                        true: { bar: true, baz: false } # rubocop:disable Lint/BooleanSymbol
                                      })

        klass_instance = klass.new(foo: true)
        expected = { foo: "true" }
        assert_equal expected, klass_instance.attributes
        assert_equal true, klass_instance.instance_variable_get(:"@bar")
        assert_equal false, klass_instance.instance_variable_get(:"@baz")
      end

      def test_attribute_default_group_raises_an_error_for_improperly_formed_groups
        klass = base_class
        klass.attribute :theme

        klass.attribute_default_group(theme: { test: true })

        exception = assert_raises(RuntimeError) do
          klass.new(theme: :test)
        end

        message = "In argument group `:test`, value `true` must be a hash."

        assert_includes message, exception.message
      end

      def test_validates_attrs_raises_exception
        klass = base_class
        klass.attribute :foo
        klass.validates_attr :foo, presence: true

        exception = assert_raises(ActiveModel::ValidationError) do
          klass_instance = klass.new
          klass_instance.validate!
        end
        assert_includes exception.message, "Attribute foo can't be blank"
      end

      def test_validates_attrs_passes
        klass = base_class
        klass.attribute :foo
        klass.validates_attr :foo, presence: true

        klass_instance = klass.new(foo: true)
        assert klass_instance.valid?
      end

      def test_validates_attrs_with_choices_option_raises_exception
        klass = base_class
        klass.attribute :size
        klass.validates_attr :size, choices: %w[small medium large]

        exception = assert_raises(ActiveModel::ValidationError) do
          klass_instance = klass.new(size: "xlarge")
          klass_instance.validate!
        end
        assert_includes exception.message, %(Attribute size "xlarge" is not valid.)
        assert_includes exception.message, %(Options include: "small", "medium", or "large")
      end

      def test_validates_attrs_with_choices_option_passes
        klass = base_class
        klass.attribute :size
        klass.validates_attr :size, choices: %w[small medium large]

        klass_instance = klass.new(size: "small")
        assert klass_instance.valid?

        # Equally validates symbols and strings
        klass_instance = klass.new(size: :small)
        assert klass_instance.valid?
      end
    end
  end
end
