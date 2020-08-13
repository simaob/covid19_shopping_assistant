class MapController < ApplicationController
  before_action :set_fields, :set_labels, :set_role, only: [:index]
  include EnumI18nHelper

  # GET /stores
  # GET /stores.json
  def index
    authorize! :read, :map

    @bounds = if params[:coordinates].present?
                params[:coordinates].map { |s| s.split(',').map(&:to_f) }
              else
                default_bounds
              end

    @shops = Store.where.not(latitude: nil).where.not(longitude: nil)
      .where.not(state: :archived).in_bounding_box(@bounds)

    if current_user.store_owner?
      @shops = @shops.where(id: current_user.user_stores.where(approved: true).pluck(:store_id))
    end

    @shops = @shops.where(store_type: :beach) if current_user.beach_admin?

    @shops = @shops.index_by(&:id)

    respond_to do |format|
      format.html { render :index }
      format.json { render json: @shops, status: :ok }
    end
  end

  # POST /map
  def create
    @shop = Store.new(map_params)
    authorize! :create, @shop

    @shop.managers << current_user if current_user.store_owner?
    @shop.source = 'Community' if current_user.contributor?

    respond_to do |format|
      if @shop.save
        format.json { render json: @shop, status: :created, location: @shop }
      else
        format.json { render json: @shop.errors, status: :unprocessable_entity }
      end
    end
    # TODO: mark as to validate
  end

  def update
    # PUT /map/:id?name=myname
    @shop = Store.find(params[:id])
    authorize! :update, @shop

    @shop.attributes = map_params

    respond_to do |format|
      if @shop.save
        format.json { render json: @shop, status: :ok, location: @shop }
      else
        format.json { render json: @shop.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @shop = Store.find(params[:id])
    @shop.state = 3

    respond_to do |format|
      if @shop.save
        format.json { render json: @shop, status: :ok, location: @shop }
      else
        format.json { render json: @shop.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  def map_params
    params.permit(:name, :group, :street, :city,
                  :zip_code, :country, :district, :store_type,
                  :latitude, :longitude, :capacity, :details, :coordinates)
  end

  def set_fields
    @fields = [
      {
        attribute: 'name',
        label: Store.human_attribute_name(:name),
        type: 'text'
      },
      {
        attribute: 'store_type',
        label: Store.human_attribute_name(:store_type),
        type: 'select',
        options: enum_options_for_select(Store, :store_type)
      },
      {
        attribute: 'group',
        label: Store.human_attribute_name(:group),
        type: 'text'
      },
      {
        attribute: 'street',
        label: Store.human_attribute_name(:street),
        type: 'text'
      },
      {
        attribute: 'zip_code',
        label: Store.human_attribute_name(:zip_code),
        type: 'text'
      },
      {
        attribute: 'city',
        label: Store.human_attribute_name(:city),
        type: 'text'
      },
      {
        attribute: 'country',
        label: Store.human_attribute_name(:country),
        type: 'text'
      },
      {
        attribute: 'details',
        label: Store.human_attribute_name(:details),
        type: 'textarea'
      },
      {
        attribute: 'latitude',
        label: Store.human_attribute_name(:latitude),
        type: 'text'
      },
      {
        attribute: 'longitude',
        label: Store.human_attribute_name(:longitude),
        type: 'text'
      }
    ]
  end

  def set_labels
    @labels = {
      delete: t('views.map.index.delete'),
      edit: t('views.map.index.edit'),
      add_store: t('views.map.index.add_store'),
      delete_store: t('views.map.index.delete_store'),
      close: t('views.map.index.close'),
      cancel: t('views.map.index.cancel'),
      save: t('views.map.index.save'),
      confirm: t('views.map.index.confirm'),
      editing: t('views.map.index.editing'),
      deleting: t('views.map.index.deleting'),
      creating: t('views.map.index.creating'),
      remove_note: t('views.map.index.remove_note'),
      state_live: t('activerecord.enums.store.states.live'),
      state_marked_for_deletion: t('activerecord.enums.store.states.marked_for_deletion'),
      state_waiting_approval: t('activerecord.enums.store.states.waiting_approval')
    }
  end

  def default_bounds
    bounds = {
      'pt' => [
        [-8.693305501609501, 41.11531424472605],
        [-8.520026252042584, 41.17823491872437]
      ],
      'es' => [
        [-3.941566736714776, 40.328785315750025],
        [-3.4482048268615415, 40.515118259540344]
      ],
      'sk' => [
        [16.641476790705553, 47.6684309174384],
        [22.732738732476804, 49.66387636689515]
      ]
    }
    bounds.fetch(I18n.locale.to_s) { bounds['pt'] }
  end

  def set_role
    @role = current_user.role
  end
end
