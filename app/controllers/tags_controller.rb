class TagsController < ApplicationController
  include ActionView::Helpers::NumberHelper
  require 'set'

  before_action :set_tag, only: [:show, :edit, :update, :destroy]
  before_action :authenticate_admin!, only: [:index, :new, :edit, :create, :update, :destroy]

  # GET /tags
  # GET /tags.json
  def index
    @tags = Tag.all
  end

  # GET /tags/1
  # GET /tags/1.json
  def show
    @query = params[:query]

    if @query
      if redirectOnEspecialCode @query
        return
      end
    end
    
    if @query
        @tokens = @query.scan(/\w+|\W/)
      if @tokens.first == '/'
        @stream = Article.where(law: @tag.laws).where('number LIKE ?', "%#{@tokens.second}%").group_by(&:law_id)
        @grouped_laws = []
        @stream.each do |grouped_law|
          law = {count: grouped_law[1].count, law: Law.find_by_id(grouped_law[0]), preview: ("<b>Artículo " + grouped_law[1].first.number + ":</b> " + grouped_law[1].first.body[0,300] + "...").html_safe}
          law[:materia_names] = law[:law].materia_names
          @grouped_laws.push(law)
          #@result_count += grouped_law[1].count
          #legal_documents.add(grouped_law[0])
        end
        @grouped_laws = @grouped_laws.sort_by{|k|k[:count]}.reverse
      else
        @query = params[:query]
        @laws = @tag.laws.search_by_name(@query).with_pg_search_highlight
        @stream = Article.where(law: @tag.laws).search_by_body(@query).group_by(&:law_id)
        @result_count = @laws.size
        @articles_count = @stream.size
        legal_documents = Set[]

        @laws.each do |law|
          legal_documents.add(law.id)
        end
        
        @grouped_laws = []
        @stream.each do |grouped_law|
          law = {count: grouped_law[1].count, law: Law.find_by_id(grouped_law[0]), preview: ("<b>Artículo " + grouped_law[1].first.number + ":</b> " + grouped_law[1].first.body[0,300] + "...").html_safe}
          law[:materia_names] = law[:law].materia_names
          @grouped_laws.push(law)
          @result_count += grouped_law[1].count
          legal_documents.add(grouped_law[0])
        end
        @grouped_laws = @grouped_laws.sort_by{|k|k[:count]}.reverse
        @legal_documents_count = legal_documents.size
        if @result_count == 1
          @result_info_text = number_with_delimiter(@result_count, :delimiter => ',').to_s + ' resultado encontrado en la materia ' + @tag.name
        else
          @result_info_text = number_with_delimiter(@result_count, :delimiter => ',').to_s + ' resultados encontrados en la materia ' + @tag.name
        end
        if @legal_documents_count > 1
          @result_info_text += " en " + @legal_documents_count.to_s + " documentos legales."
        elsif @legal_documents_count == 1
          @result_info_text += " en " + @legal_documents_count.to_s + " documento legal."
        end
      end
    else
      @laws = @tag.laws
      @result_count = @laws.count
      if @result_count == 1
        @result_info_text = number_with_delimiter(@result_count, :delimiter => ',').to_s + ' documento legal.'
      else
        @result_info_text = number_with_delimiter(@result_count, :delimiter => ',').to_s + ' documentos legales.'
      end
    end
  end

  # GET /tags/new
  def new
    @tag = Tag.new
  end

  # GET /tags/1/edit
  def edit
  end

  # POST /tags
  # POST /tags.json
  def create
    @tag = Tag.new(tag_params)
    respond_to do |format|
      if @tag.save
        format.html { redirect_to @tag, notice: 'Tag was successfully created.' }
        format.json { render :show, status: :created, location: @tag }
      else
        format.html { render :new }
        format.json { render json: @tag.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /tags/1
  # PATCH/PUT /tags/1.json
  def update
    respond_to do |format|
      if @tag.update(tag_params)
        format.html { redirect_to @tag, notice: 'Tag was successfully updated.' }
        format.json { render :show, status: :ok, location: @tag }
      else
        format.html { render :edit }
        format.json { render json: @tag.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /tags/1
  # DELETE /tags/1.json
  def destroy
    @tag.destroy
    respond_to do |format|
      format.html { redirect_to tags_url, notice: 'Tag was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_tag
      @tag = Tag.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def tag_params
      params.require(:tag).permit(:name, :tag_type_id)
    end
end
