module Symbols
  def symbols_from_library(library)
    syms = `nm -gU #{library}`.split("\n")
    classes = classes_from_symbols(syms)
    result = classes
    result += constants_from_symbols(syms)
    result += categories_selectors(library, classes)

    result.reject { |e| e == 'llvm.cmdline' || e == 'llvm.embedded.module' }
  end

  module_function :symbols_from_library

  private

  def classes_from_symbols(syms)
    classes = syms.select { |klass| klass[/OBJC_CLASS_\$_/] }
    classes = classes.uniq
    classes.map! { |klass| klass.gsub(/^.*\$_/, '') }
  end

  def constants_from_symbols(syms)
    consts = syms.select { |const| const[/ S /] }
    consts = consts.select { |const| const !~ /OBJC|\.eh/ }
    consts = consts.uniq
    consts = consts.map! { |const| const.gsub(/^.* _/, '') }

    other_consts = syms.select { |const| const[/ T /] }
    other_consts = other_consts.uniq
    other_consts = other_consts.map! { |const| const.gsub(/^.* _/, '') }

    consts + other_consts
  end
    
  def categories_selectors(library, classes)
    #see cocoapods-mangle https://github.com/intercom/cocoapods-mangle
    symbols = `nm -U #{library}`.split("\n")
    selectors = symbols.select { |selector| selector[/ t [-|+]\[[^ ]*\([^ ]*\) [^ ]*\]/] }
    selectors = selectors.reject do |selector|
      class_name = selector[/[-|+]\[(.*?)\(/m, 1]
      classes.include? class_name
    end
    selectors = selectors.map { |selector| selector[/[^ ]*\]\z/][0...-1] }
    selectors = selectors.map { |selector| selector.split(':').first }
    selectors.uniq
  end

  module_function :classes_from_symbols
  module_function :constants_from_symbols
  module_function :categories_selectors
end
