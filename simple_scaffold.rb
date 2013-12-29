def generate_controller(update_method, params, include_white_list_code=false)
  strong_params_method=white_list_code if include_white_list_code
  controller_code = <<-CODE
<% if namespaced? -%>
require_dependency "<%= namespaced_file_path %>/application_controller"

<% end -%>
<% module_namespacing do -%>
class <%= controller_class_name %>Controller < ApplicationController

  def index
    @<%= plural_table_name %> = <%= orm_class.all(class_name) %>
    render 'index'
  end

  def show
    @<%= singular_table_name %> = <%= orm_class.find(class_name, "params[:id]") %>
    render 'show'
  end

  def new
    @<%= singular_table_name %> = <%= orm_class.build(class_name) %>
    render 'new'
  end

  def edit
    @<%= singular_table_name %> = <%= orm_class.find(class_name, "params[:id]") %>
    render 'edit'
  end

  def create
    @<%= singular_table_name %> = <%= orm_class.build(class_name, "#{params}") %>

    if @<%= orm_instance.save %>
      redirect_to @<%= singular_table_name %>, notice: <%= "'\#{human_name} was successfully created.'" %>
    else
      render action: 'new'
    end
  end

  def update
    @<%= singular_table_name %> = <%= orm_class.find(class_name, "params[:id]") %>
    if @<%= orm_instance.#{update_method}("#{params}") %>
      redirect_to @<%= singular_table_name %>, notice: <%= "'\#{human_name} was successfully updated.'" %>
    else
      render action: 'edit'
    end
  end

  def destroy
    @<%= singular_table_name %> = <%= orm_class.find(class_name, "params[:id]") %>
    @<%= orm_instance.destroy %>
    redirect_to <%= index_helper %>_url, notice: <%= "'\#{human_name} was successfully destroyed.'" %>
  end
#{strong_params_method}
end
<% end -%>
  CODE
  file 'lib/templates/rails/scaffold_controller/controller.rb', controller_code
end

def white_list_code
  <<-CODE

  private
  # Only allow a trusted parameter "white list" through.
  def <%= "\#{singular_table_name}_params" %>
    <%- if attributes_names.empty? -%>
    params[<%= ":\#{singular_table_name}" %>]
    <%- else -%>
    params.require(<%= ":\#{singular_table_name}" %>).permit(<%= attributes_names.map { |name| ":\#{name}" }.join(', ') %>)
    <%- end -%>
  end
  CODE
end

environment 'config.generators.assets = false'
environment 'config.generators.helper = false'
environment 'config.generators.test_framework = false'
environment 'config.generators.stylesheets = false'

if Rails::VERSION::MAJOR>3
  environment 'config.generators.jbuilder = false'
  generate_controller("update", "\#{singular_table_name}_params", true)
else
  generate_controller("update_attributes", "params[:\#{singular_table_name}]")
end
