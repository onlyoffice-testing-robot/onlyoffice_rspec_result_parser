class ResultCreator
  def push_to_end(describe, level)
    if level == 0
      @final_result = describe
    else
      @final_result.find_last_on_lvl(level - 1).child << describe if level > 0
    end
  end

  def get_result
    @final_result
  end
end