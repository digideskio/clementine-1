class Admin::ProjectsController < AdminController
  before_action :set_project, only: [:show, :edit, :update, :destroy, :proposal_download]

  def proposal_download
    @company = Company.first
    @project_phases = @project.project_phases.rank(:phase_order)
    html = render_to_string('admin/projects/pdf_proposal.html.erb', layout: 'pdfs/layout_pdf')
    pdf = WickedPdf.new.pdf_from_string(html)
    send_data(pdf,
      filename: "proposal.pdf",
      type: 'application/pdf',
      disposition: 'attachement')
  end
  # GET /projects
  # GET /projects.json
  def index
    @projects = Project.all
  end

  # GET /projects/1
  # GET /projects/1.json
  def show
    @company = Company.first
    @project_phases = @project.project_phases.rank(:phase_order)
  end

  # GET /projects/new
  def new
    @project = Project.new
  end

  # GET /projects/1/edit
  def edit
  end

  # POST /projects
  # POST /projects.json
  def create
    @project = Project.new(project_params)

    respond_to do |format|
      if @project.save
        # if a platform is set create all the project phases
        if params[:project][:platform]
          project_type = "Project::PROJECT_PHASES_#{@project.platform.upcase}"
          project_type.constantize.each do |phase|
            @project.project_phases.create(title: phase[0], description: phase[1])
          end
        end
        if params[:project][:origin] == 'form'
          format.html { redirect_to new_project_path, notice: "Thank you! We will be in touch shortly"}
        else
          raise 'hell'
          format.html { redirect_to admin_project_path(@project), notice: 'Project was successfully created.' }
          format.json { render :show, status: :created, location: @project }
        end
      else
        format.html { render :new }
        format.json { render json: @project.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /projects/1
  # PATCH/PUT /projects/1.json
  def update
    respond_to do |format|
      if @project.update(project_params)
        if @project.platform_previously_changed? && @project.platform.present?
          project_type = "Project::PROJECT_PHASES_#{@project.platform.upcase}"
          project_type.constantize.each do |phase|
            @project.project_phases.create(title: phase[0], description: phase[1])
          end
        end
        format.html { redirect_to admin_project_path(@project), notice: 'Project was successfully updated.' }
        format.json { render :show, status: :ok, location: @project }
      else
        format.html { render :edit }
        format.json { render json: @project.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /projects/1
  # DELETE /projects/1.json
  def destroy
    @project.destroy
    respond_to do |format|
      format.html { redirect_to admin_projects_path, notice: 'Project was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_project
      @project = Project.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def project_params
      params.require(:project).permit(:name, :description, :project_contact, :project_email, :app_type, :design_needed, :inspiration, :start_date, :end_date, :budget_range, :about_the_project, :potential_new, :paid, :client_id, :status, :platform, :design_status, project_phases_attributes:[:id, :title, :description, :_destroy],project_documents_attributes:[:id, :title, :project_id, :doc, :_destroy])
    end
end
