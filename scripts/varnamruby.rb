require 'ffi'
require 'singleton'

# Ruby wrapper for libvarnam
module VarnamLibrary
  extend FFI::Library
  ffi_lib $options[:library]

  VARNAM_SYMBOL_MAX      = 30

  class Token < FFI::Struct
    layout :id, :int,
    :type, :int,
    :match_type, :int,
    :tag, [:char, VARNAM_SYMBOL_MAX],
    :pattern, [:char, VARNAM_SYMBOL_MAX],
    :value1, [:char, VARNAM_SYMBOL_MAX],
    :value2, [:char, VARNAM_SYMBOL_MAX],
    :value3, [:char, VARNAM_SYMBOL_MAX]
  end

  class Word < FFI::Struct
    layout :text, :string,
    :confidence, :int
  end

  attach_function :varnam_init, [:string, :pointer, :pointer], :int
  attach_function :varnam_transliterate, [:pointer, :string, :pointer], :int
  attach_function :varnam_reverse_transliterate, [:pointer, :string, :pointer], :int
  attach_function :varnam_learn, [:pointer, :string], :int
  attach_function :varnam_learn_from_file, [:pointer, :string, :pointer, :pointer, :pointer], :int
  attach_function :varnam_create_token, [:pointer, :string, :string, :string, :string, :string, :int, :int, :int], :int
  attach_function :varnam_generate_cv_combinations, [:pointer], :int
  attach_function :varnam_set_scheme_details, [:pointer, :string, :string, :string, :string, :string], :int
  attach_function :varnam_get_last_error, [:pointer], :string
  attach_function :varnam_flush_buffer, [:pointer], :int
  attach_function :varnam_config, [:pointer, :int, :varargs], :int
  attach_function :varnam_get_all_tokens, [:pointer, :int, :pointer], :int
  attach_function :varnam_set_scheme_details, [:pointer, :string, :string, :string, :string, :string], :int
  attach_function :varray_get, [:pointer, :int], :pointer
  attach_function :varray_length, [:pointer], :int
end

VarnamToken = Struct.new(:type, :pattern, :value1, :value2, :value3, :tag, :match_type)
VarnamWord = Struct.new(:text, :confidence)

module Varnam
  VARNAM_TOKEN_VOWEL           = 1
  VARNAM_TOKEN_CONSONANT       = 2
  VARNAM_TOKEN_DEAD_CONSONANT  = 3
  VARNAM_TOKEN_CONSONANT_VOWEL = 4
  VARNAM_TOKEN_NUMBER          = 5
  VARNAM_TOKEN_SYMBOL          = 6
  VARNAM_TOKEN_ANUSVARA        = 7
  VARNAM_TOKEN_VISARGA         = 8
  VARNAM_TOKEN_VIRAMA          = 9
  VARNAM_TOKEN_OTHER           = 10
  VARNAM_TOKEN_NON_JOINER      = 11

  VARNAM_MATCH_EXACT           = 1
  VARNAM_MATCH_POSSIBILITY     = 2

  VARNAM_CONFIG_USE_DEAD_CONSONANTS    = 100
  VARNAM_CONFIG_IGNORE_DUPLICATE_TOKEN = 101
  VARNAM_CONFIG_ENABLE_SUGGESTIONS = 102

  class RuntimeContext
    include Singleton

    def initialize
      @errors = 0
      @warnings = 0
      @tokens = {}
      @current_expression = ""
      @error_messages = []
      @warning_messages = []
      @current_tag = nil
    end

    def errored
      @errors += 1
    end

    def warned
      @warnings += 1
    end

    def errors
      @errors
    end

    def warnings
      @warnings
    end

    attr_accessor :tokens, :current_expression, :error_messages, :warning_messages, :current_tag
  end
end

def _context
  return Varnam::RuntimeContext.instance
end

def get_source_file_with_linenum
  Kernel::caller.last.sub(":in `<main>'", "")  # We don't need :in `<main>' to appear and make confusion
end

def inform(message)
  puts "   #{message}"
end

def warn(message)
  if _context.current_expression.nil?
    _context.warning_messages.push "#{get_source_file_with_linenum} : WARNING: #{message}"
  else
    _context.warning_messages.push "#{get_source_file_with_linenum} : WARNING: In expression #{_context.current_expression}. #{message}"
  end
  _context.warned
end

def error(message)
  if _context.current_expression.nil?
    _context.error_messages.push "#{get_source_file_with_linenum} : ERROR : #{message}"
  else
    _context.error_messages.push "#{get_source_file_with_linenum} : ERROR : In expression #{_context.current_expression}. #{message}"
  end
  _context.errored
end