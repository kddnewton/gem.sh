class GemsController < ApplicationController
  before_action :set_gem, except: [:index, :search]
  before_action :set_target, only: [:instance_method, :class_method]
  before_action :set_namespaces, except: [:index, :search]

  def index
    @gems = Gem::Specification.all.sort_by(&:name)
  end

  def show
  end

  def search
    @result = GemSearch.search(params[:name])
  end

  def namespace
    @namespace = find_module(params[:module]) || go_back
    @classes = @gem.classes.select { |namespace| namespace.namespace == params[:module] }
  end

  def klass
    @klass = find_class(params[:class]) || go_back
    @namespace = find_module(@klass.namespace)
  end

  def instance_method
    @method = @target.instance_methods.find { |instance_method| instance_method.name == params[:name] }

    render :method
  end

  def class_method
    @method = @target.class_methods.find { |class_method| class_method.name == params[:name] }

    render :method
  end

  def source
    file = params[:file]
    source_path = "#{@gem.unpack_data_path}/#{file}"

    if file && @gem.files.include?(file) && File.exist?(source_path)
      @file = OpenStruct.new(path: file, content: File.read(source_path))
    end
  end

  private

  def find_class(name)
    @gem.classes.find { |klass| klass.qualified_name == name }
  end

  def find_module(name)
    @gem.modules.find { |namespace| namespace.qualified_name == name }
  end

  def go_back
    redirect_to gem_version_path(@gem.name, @gem.version)
  end

  def set_gem
    @gem = GemSpec.find(params[:gem], params[:version]) || redirect_to(gems_path)
  end

  def set_target
    if params[:class]
      @target = find_class(params[:class]) || go_back
      @namespace = find_module(@target.namespace)
    elsif params[:module]
      @target = find_module(params[:module]) || go_back
    else
      @target = @gem.info.analyzer
    end
  end

  def set_namespaces
    @namespaces = @gem.modules.select { |namespace| namespace.namespace.split("::").count <= 1 }
  end
end
