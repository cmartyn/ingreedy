class IngreedyParser

  attr_reader :amount, :unit, :ingredient, :query, :fraction_display

  def initialize(query)
    @query = query
  end

  def parse
    ingreedy_regex = %r{
      (?<amount> .?\d+(\.\d+)? ) {0}
      (?<fraction> \d\/\d ) {0}

      (?<container_amount> \d+(\.\d+)?) {0}
      (?<container_unit> .+) {0}
      (?<container_size> \(\g<container_amount>\s\g<container_unit>\)) {0}
      (?<unit_and_ingredient> .+ ) {0}

      (\g<fraction>\s)?(\g<amount>\s?)?(\g<fraction>\s)?(\g<container_size>\s)?\g<unit_and_ingredient>
    }x
    results = ingreedy_regex.match(@query)

    @ingredient_string = results[:unit_and_ingredient]
    @container_amount = results[:container_amount]
    @container_unit = results[:container_unit]

    parse_fraction_display results[:amount], results[:fraction]
    parse_amount results[:amount], results[:fraction]
    parse_unit_and_ingredient
  end

  private

  def parse_fraction_display(amount_string, fraction_string)
    @fraction_display = "#{amount_string.to_s} #{fraction_string.to_s}".strip
  end

  def parse_amount(amount_string, fraction_string)
    fraction = 0
    if fraction_string
      numbers = fraction_string.split("\/")
      numerator = numbers[0].to_f
      denominator = numbers[1].to_f
      fraction = numerator / denominator
    end
    @amount = amount_string.to_f + fraction
    @amount *= @container_amount.to_f if @container_amount
  end

  def set_unit_variations(unit, variations)
    variations.each do |abbrev|
      @unit_map[abbrev] = unit
    end
  end

  def create_unit_map
    @unit_map = {}
    # english units
    set_unit_variations :cup, ["c.", "c", "cup", "cups"]
    set_unit_variations :fl_oz, ["fl. oz.", "fl oz", "fluid ounce", "fluid ounces"]
    set_unit_variations :gal, ["gal", "gal.", "gallon", "gallons"]
    set_unit_variations :oz, ["oz", "oz.", "ozs", "ozs.", "ounce", "ounces"]
    set_unit_variations :pt, ["pt", "pt.", "pint", "pints"]
    set_unit_variations :lb, ["lb", "lb.", "lbs", "lbs.", "pound", "pounds"]
    set_unit_variations :qt, ["qt", "qt.", "qts", "qts.", "quart", "quarts"]
    set_unit_variations :tbs, ["tbsp.", "tbsp", "tbs.", "tbs", "tb", "tb.", "T", "T.", "tablespoon", "tablespoons", "table spoon", "table spoons"]
    set_unit_variations :tsp, ["t", "t.", "ts", "ts.", "tsp", "tsp.", "teaspoon", "tea spoon", "teaspoons", "tea spoons"]
    set_unit_variations :in, ["inch", "inches"]
    # metric units
    set_unit_variations :g, ["g", "g.", "gr", "gr.", "gram", "grams"]
    set_unit_variations :kg, ["kg", "kg.", "kilogram", "kilograms"]
    set_unit_variations :L, ["l", "l.", "liter", "liters"]
    set_unit_variations :mg, ["mg", "mg.", "milligram", "milligrams"]
    set_unit_variations :mL, ["ml", "ml.", "milliliter", "milliliters"]
    # non-specific units
    set_unit_variations :dash, ["dash", "a dash", "dashes"]
    set_unit_variations :pinch, ["pinch", "a pinch", "pinches"]
    set_unit_variations :handful, ["handful", "a handful", "handfuls"]
    set_unit_variations :sprig, ["sprig", "a sprig", "sprigs"]
    set_unit_variations :bunch, ["bunch", "a bunch", "bunches"]
    set_unit_variations :stick, ["stick", "a stick", "sticks"]
    set_unit_variations :clove, ["clove", "cloves"]
    set_unit_variations :can, ["can", "cans"]
    set_unit_variations :package, ["package", "packages"]
    set_unit_variations :bag, ["bag", "bags"]
    set_unit_variations :capful, ["capful", "capfuls"]
    set_unit_variations :cube, ["cube", "cubes"]
    set_unit_variations :jar, ["jar", "jars"]
    set_unit_variations :container, ["container", "containers"]
    
    set_unit_variations :egg, ["egg", "eggs"]
    set_unit_variations :pinch, ["pinch", "pinches"]
  end

  def parse_unit
    create_unit_map if @unit_map.nil?

    @unit_map.each do |abbrev, unit|
      if @ingredient_string.start_with?(abbrev + " ")
        # if a unit is found, remove it from the ingredient string
        @ingredient_string.sub! abbrev, ""
        @unit = unit
      end
    end

    # if no unit yet, try it again downcased
    if @unit.nil?
      @ingredient_string.downcase!
      @unit_map.each do |abbrev, unit|
        if @ingredient_string.start_with?(abbrev + " ")
          # if a unit is found, remove it from the ingredient string
          @ingredient_string.sub! abbrev, ""
          @unit = unit
        end
      end
    end

    # if we still don't have a unit, check to see if we have a container unit
    if @unit.nil? and @container_unit
      @unit_map.each do |abbrev, unit|
        @unit = unit if abbrev == @container_unit
      end
    end
  end

  def parse_unit_and_ingredient
    parse_unit
    # clean up ingredient string
    @ingredient = @ingredient_string.lstrip.rstrip
  end
end
