module Kaminari
  def self.meta_pagination(paginated_obj, options = {})
    options[:meta] = {} unless options.key?(:meta)
    meta_options = options[:meta].merge(generate_pagination(paginated_obj))
    options[:meta] = meta_options
    options
  end

  def self.generate_pagination(paginated_obj)
    {
      pagination: {
        current_page: paginated_obj.current_page,
        prev_page: paginated_obj.prev_page,
        next_page: paginated_obj.next_page,
        total_pages: paginated_obj.total_pages,
        total_count: paginated_obj.total_count
      }
    }
  end
end
