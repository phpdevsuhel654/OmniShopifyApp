# frozen_string_literal: true

class ApiController < ApplicationController
  # disable the CSRF protection
  skip_before_action :verify_authenticity_token

  # index action
  def index
    @params = params
  end

  # get shop order data by using shop url and order no
  # api/get_order_data
  # @shop i.e. queuefirst.myshopify.com
  # @order_no i.e. 1038
  def get_order_data
    # Get header variables
    shop_url = request.headers['OmniRPS-Shopify-Domain']
    token = request.headers['OmniRPS-Shopify-Token']
    # shop_url = params[:shop]
    order_no = params[:order_no]
    @response = Hash.new
    if !order_no.nil? && !order_no.empty? && !shop_url.nil? && !shop_url.empty?
      # Get shop data
      get_shop_data = Shop.where(shopify_domain: shop_url).first
      #Check shop data available in database
      if !get_shop_data.nil?
        get_shop_setting_data = ShopSetting.where(shop_id: get_shop_data["id"]).first
        if get_shop_setting_data.nil?
          @response["Success"] = 0
          @response["Message"] = "Please properly configure the App."
          @response["Data"] = ""
        elsif token == get_shop_setting_data['token']
          # Create Shopify API session
          session = ShopifyAPI::Session.new(domain: get_shop_data['shopify_domain'], token: get_shop_data['shopify_token'], api_version: "2019-04")
          
          # Activate shopify new session
          ShopifyAPI::Base.activate_session(session)
          
          # Get shopify order data
          shopify_order_number = order_no.gsub("#", "")
          order_data = ShopifyAPI::Order.find(:first, :params => {:name => shopify_order_number})
          # order_data = ShopifyAPI::Order.find(:all, params: { order_number: order_no, :limit => 1, :order => "created_at ASC"})

          @response["Success"] = 1
          @response["Message"] = "You have successfully got the order data."
          @response["Data"] = order_data
        else
          @response["Success"] = 0
          @response["Message"] = "Please provide a valid token."
          @response["Data"] = ""
        end
      else
        @response["Success"] = 0
        @response["Message"] = "Something went wrong!"
        @response["Data"] = ""
      end
    else
      @response["Success"] = 0
      @response["Message"] = "Something went wrong!"
      @response["Data"] = ""
    end
    # Convert Hash value to JSON
    @response = @response
    # Render JSON data
    render :json => @response
  end

  # get shop settings data by using shop domain
  def get_shop_settings_data(shop_url='', token='')
    shop_settings = Hash.new
    # Get shop data
    get_shop_data = Shop.where(shopify_domain: shop_url).first
    if !get_shop_data.nil?
      shop_id = get_shop_data.id
      # Get shop settings data
      get_shop_setting_data = ShopSetting.where(shop_id: shop_id).first
      if get_shop_setting_data.nil?
        shop_settings['Success'] = 0
        shop_settings["Message"] = "Please properly configure the App."
      elsif get_shop_setting_data['token'] = token
        # Get shop data
        shop_product_exclusion_tags = ProductExclusionTag.select("id, tag").find_by(shop_id: shop_id)
        shop_reason_ids_data = ShopReason.find_by(shop_id: shop_id)
        unless shop_reason_ids_data.nil?
          shop_reasons = Reason.select("id, reason").where(id: JSON.parse(shop_reason_ids_data.reason_ids)).find_all
        else
          shop_reasons = Reason.select("id, reason").find_all
        end
        shop_rules_data = Rule.select("rules.id, rules.id as rule_id, rules.name, rules.priority, rules.conditions, rule_options.id as rule_option_id, rule_options.refund_method, rule_options.return_window, rule_options.return_shipping_fee").joins("LEFT JOIN rule_options ON rule_options.rule_id = rules.id").where(shop_id: shop_id).order("rules.priority ASC").find_all
        shop_rules = Array.new
        i = 0
        shop_rules_data.each do |rule|
          tmp_hash = Hash.new
          tmp_hash['rule_id'] = rule.id
          tmp_hash['name'] = rule.name
          tmp_hash['priority'] = rule.priority
          tmp_hash['conditions'] = JSON.parse(rule.conditions)
          tmp_hash['rule_option_id'] = rule.rule_option_id
          tmp_hash['refund_method'] = rule.refund_method
          tmp_hash['return_window'] = rule.return_window
          tmp_hash['return_shipping_fee'] = rule.return_shipping_fee
          shop_rules[i] = tmp_hash
          i = i + 1;
        end
        if !shop_product_exclusion_tags.nil? && !shop_product_exclusion_tags.tag.nil?
          shop_settings['shop_product_exclusion_tags'] = shop_product_exclusion_tags.tag
        else
          shop_settings['shop_product_exclusion_tags'] = 'no-returns'
        end
        shop_settings['shop_reasons'] = shop_reasons
        shop_settings['shop_rules'] = shop_rules
        shop_settings['Success'] = 1
        shop_settings["Message"] = "You have successfully got the shop settings."
      else
        shop_settings['Success'] = 0
        shop_settings["Message"] = "Please provide a valid token."
      end
    end
    return shop_settings
  end

  # Get shop settings data
  # api/get_shop_settings
  # @shop
  def get_shop_settings
    @params = params
    # Get header variables
    shop_url = request.headers['OmniRPS-Shopify-Domain']
    token = request.headers['OmniRPS-Shopify-Token']
    # shop_url = params[:shop]
    @shop_settings = Hash.new
    @shop_settings = self.get_shop_settings_data(shop_url, token)
    render :json => @shop_settings
  end

  # Get product data
  # api/get_product_data
  # @shop
  # @product_id
  def get_product_data
    # Get header variables
    shop_url = request.headers['OmniRPS-Shopify-Domain']
    token = request.headers['OmniRPS-Shopify-Token']
    # shop_url = params[:shop]
    product_id = params[:product_id]
    @response = Hash.new
    if !product_id.nil? && !product_id.empty? && !shop_url.nil? && !shop_url.empty?
      # Get shop data
      get_shop_data = Shop.where(shopify_domain: shop_url).first
      #Check shop data available in database
      if !get_shop_data.nil?
        get_shop_setting_data = ShopSetting.where(shop_id: get_shop_data["id"]).first
        if get_shop_setting_data.nil?
          @response["Success"] = 0
          @response["Message"] = "Please properly configure the App."
          @response["Data"] = ""
        elsif token == get_shop_setting_data['token']
          # Create Shopify API session
          session = ShopifyAPI::Session.new(domain: get_shop_data['shopify_domain'], token: get_shop_data['shopify_token'], api_version: "2019-04")
          
          # Activate shopify new session
          ShopifyAPI::Base.activate_session(session)
          
          # Get shopify order data
          product_data = ShopifyAPI::Product.find(product_id)
          # product_data = ShopifyAPI::Variant.where(sku: 'QF0000000008').first

          @response["Success"] = 1
          @response["Message"] = "You have successfully got the product data."
          @response["Data"] = product_data
        else
          @response["Success"] = 0
          @response["Message"] = "Something went wrong!"
          @response["Data"] = ""
        end
      else
        @response["Success"] = 0
        @response["Message"] = "Something went wrong!"
        @response["Data"] = ""
      end
    else
      @response["Success"] = 0
      @response["Message"] = "Something went wrong!"
      @response["Data"] = ""
    end
    # Convert Hash value to JSON
    @response = @response
    # Render JSON data
    render :json => @response
  end

  # Check rule conditions
  def check_rule_conditions(cond_field_value, cond_param, cond_value, order_data)
    return_val=0
    if cond_param == 'IET'
      if cond_field_value == 'OC'
        # if order_data['shipping_address']['country_code'] == cond_value
        if order_data.shipping_address.country_code == cond_value
          return_val = 1
        end
      elsif cond_field_value == 'ORR'
        if params[:ReturnReason] == cond_value
          return_val = 1
        end
      end
    elsif cond_param == 'INET'
      if cond_field_value == 'OC'
        if order_data.shipping_address.country_code != cond_value
          return_val = 1
        end
      elsif cond_field_value == 'ORR'
        if params[:ReturnReason] != cond_value
          return_val = 1
        end
      end
    elsif cond_param == 'GT'
      if cond_field_value == 'OV'
        if order_data.total_price. > cond_value
          return_val = 1
        end
      elsif cond_field_value == 'ODV'
        if order_data.total_discount > cond_value
          return_val = 1
        end
      elsif cond_field_value == 'ODP'
        discount_per = (order_data.total_discount*100)/order_data.total_price;
        if discount_per > cond_value
          return_val = 1
        end
      end
    elsif cond_param == 'LT'
      if cond_field_value == 'OV'
        if order_data.total_price < cond_value
          return_val = 1
        end
      elsif cond_field_value == 'ODV'
        if order_data.total_discount < cond_value
          return_val = 1
        end
      elsif cond_field_value == 'ODP'
        discount_per = (order_data.total_discount*100)/order_data.total_price;
        if discount_per < cond_value
          return_val = 1
        end
      end
    elsif cond_param == 'GTET'
      if cond_field_value == 'OV'
        if order_data.total_price >= cond_value
          return_val = 1
        end
      elsif cond_field_value == 'ODV'
        if order_data.total_discount >= cond_value
          return_val = 1
        end
      elsif cond_field_value == 'ODP'
        discount_per = (order_data.total_discount*100)/order_data.total_price;
        if discount_per >= cond_value
          return_val = 1
        end
      end
    elsif cond_param == 'LTET'
      if cond_field_value == 'OV'
        if order_data.total_price <= cond_value
          return_val = 1
        end
      elsif cond_field_value == 'ODV'
        if order_data.total_discount <= cond_value
          return_val = 1
        end
      elsif cond_field_value == 'ODP'
        discount_per = (order_data.total_discount*100)/order_data.total_price;
        if discount_per <= cond_value
          return_val = 1
        end
      end
    elsif cond_param == 'ET'
      if cond_field_value == 'OV'
        if order_data.total_price == cond_value
          return_val = 1
        end
      elsif cond_field_value == 'ODV'
        if order_data.total_discount == cond_value
          return_val = 1
        end
      elsif cond_field_value == 'ODP'
        discount_per = (order_data.total_discount*100)/order_data.total_price;
        if discount_per == cond_value
          return_val = 1
        end
      end
    end
    #return boolean value
    return return_val
  end

  # Make refund to the customer
  # api/refund_order_product_to_customer
  # @shop
  # @sample_request_str = {"OrderNo":"1001","ShopifyOrderId":"971253973055","ShopifyShopDomain":"gozti.myshopify.com","ReturnReason":"Found Better Price","RefundItems":[{"ShopifyOrderLineItemId":"2218298572863","ShopifyOrderProductId":"15275157356607","ShopifyOrderVariantId":"1892575608895","ItemSku":"GT0000000001","ReturnReason":"Found Better Price","ItemQuantity":"1"}]}
  def refund_order_product_to_customer
    @params = params
    # Get header variables
    shop_url = request.headers['OmniRPS-Shopify-Domain']
    token = request.headers['OmniRPS-Shopify-Token']
    #shop_url = params[:shop]
    @response = Hash.new
    
    shop_settings = Hash.new
    shop_settings = self.get_shop_settings_data(shop_url)
    refund = 3 # 0 = Order data not available, 1 = Refund, 2 = Store Credit, 3 = Rules are not set on backend
    if !shop_url.nil? && !shop_url.empty? && shop_settings['Success'] != 0
      # Get shop data
      get_shop_data = Shop.where(shopify_domain: shop_url).first
      #Check shop data available in database
      if !get_shop_data.nil?
        # Create Shopify API session
        session = ShopifyAPI::Session.new(domain: get_shop_data['shopify_domain'], token: get_shop_data['shopify_token'], api_version: "2019-04")
        
        # Activate shopify new session
        ShopifyAPI::Base.activate_session(session)
        
        unless params[:ShopifyOrderId].nil?
          order_data = ShopifyAPI::Order.find(params[:ShopifyOrderId])
        else
          shopify_order_number = params[:OrderNo].gsub("#", "")
          order_data = ShopifyAPI::Order.find(:first, :params => {:name => shopify_order_number})
        end
        # order_data = ShopifyAPI::Order.find(:first, :params => {:name => 1002})
        test_app = 0
        if order_data.nil?
          refund = 0
        else
          # logger.debug "in else"
          is_return_shipping_fee = 0
          unless shop_settings['shop_rules'].nil?
            shop_settings['shop_rules'].each do |rule|
              rule_applied = false
              unless rule['conditions']['cond_field'].nil?
                i=0
                false_cond_count=0;
                true_cond_count=0;
                rule['conditions']['cond_field'].each do |cond_field|
                  # check_cond = 0
                  check_cond = self.check_rule_conditions(cond_field, rule['conditions']['cond_param'][i], rule['conditions']['cond_value'][i], order_data)
                  if check_cond == 1
                    true_cond_count += 1;
                  else
                    false_cond_count += 0;
                  end
                  i += 1
                end
                # test_app = 1
                # render :plain => "#{true_cond_count} and #{false_cond_count} "
                # logger.debug "True Count: #{true_cond_count}, False Count: #{false_cond_count}"
                if true_cond_count > 0 || false_cond_count > 0
                  is_return_shipping_fee = rule['return_shipping_fee'];
                  rule_applied = true                
                else
                  rule_applied = false
                end
                if true_cond_count > 0 && false_cond_count == 0
                  refund = rule['refund_method'];
                  # render :json => refund
                end
              else
                rule_applied = false
              end
              if rule_applied == true
                break
              end
            end
          else
            refund = 1
          end
        end
      end
    end

    # test_app = 0
    if test_app == 0
      # render :json => refund # shop_settings['shop_rules']
      # render :json => order_data
    end


#=begin
    # refund = 2
    # Check if we do not get shop settings
    if refund == 0
      @response["Success"] = 0
      #@response["Type"] = ''
      @response["Message"] = "Order data not available."
    elsif shop_settings['Success'] == 0
      @response["Success"] = 0
      @response["Type"] = 'error'
      @response["Message"] = shop_settings['Message']
      @response["Data"] = ""
    # Apply Gift Card to Customer
    elsif refund == 2
      # Get shop data
      get_shop_data = Shop.where(shopify_domain: shop_url).first
      # Check shop data available in database
      if !get_shop_data.nil?
        get_shop_setting_data = ShopSetting.where(shop_id: get_shop_data['id']).first
      end
      store_credit_call = Hash.new
      store_credit_call_error = Hash.new
      if !get_shop_setting_data.nil? && !get_shop_setting_data['private_app_api_key'].nil? && !get_shop_setting_data['private_app_password'].nil?
        gift_card_arr = Array.new
        order_data.line_items.each do |line_item|
          params[:RefundItems].each do |item|
            if item['ShopifyOrderLineItemId'] == line_item.id
              check_gift_card_available_val = check_gift_card_available(get_shop_data['id'], order_data.id, line_item.id, order_data)
              if check_gift_card_available_val == 1
                gift_card_hash = Hash.new
                number = 15
                charset = Array('A'..'Z')
                gift_card_code = Array.new(number) { charset.sample }.join
                gift_card_hash['code'] = gift_card_code
                gift_card_hash['currency'] = order_data.currency
                gift_card_hash['customer_id'] = order_data.customer.id
                # gift_card_hash['order_id'] = order_data.id    
                # gift_card_hash['line_item_id'] = line_item.id
                # line_item_amount = line_item.price_set.presentment_money.amount;
                # line_item_tax_amount = 0
                # line_item.tax_lines.each do |tax_amount|
                #   line_item_tax_amount = line_item_tax_amount.to_f + tax_amount.price_set.presentment_money.amount.to_f
                # end
                # gift_card_hash['initial_value'] = line_item_amount.to_f + line_item_tax_amount.to_f
                line_item_amount = line_item.price;
                line_item_tax_amount = 0
                line_item.tax_lines.each do |tax_amount|
                  line_item_tax_amount = line_item_tax_amount.to_f + tax_amount.price.to_f
                end
                line_item_discount_amount = 0
                line_item.discount_allocations.each do |discount_amount|
                  line_item_discount_amount = line_item_discount_amount.to_f + discount_amount.amount.to_f
                end
                gift_card_amount = (line_item_amount.to_f + line_item_tax_amount.to_f - line_item_discount_amount.to_f).round(2)
                gift_card_hash['balance'] = gift_card_amount
                gift_card_hash['initial_value'] = gift_card_amount
                gift_card_hash['note'] = "Order No: #{order_data.order_number} - #{params[:ReturnReason]}"
                # render :json => gift_card_hash
                shopify_shop_url = shop_url
                shopify_private_app_api_key = get_shop_setting_data['private_app_api_key']
                shopify_private_app_password = get_shop_setting_data['private_app_password']
                # Call gift card api from private app
                # store_credit_call = ShopifyAPI::GiftCard.create(gift_card_hash)
                private_app_shop_domain = "#{shopify_private_app_api_key}:#{shopify_private_app_password}@#{shopify_shop_url}"
                ShopifyAPI::Session.temp(domain: private_app_shop_domain, token: shopify_private_app_password, api_version: ShopifyApp.configuration.api_version) do
                  # @response =  ShopifyAPI::GiftCard.find(:all)
                  # render :json =>  @order
                  # Call gift card api from private app
                  # store_credit_call = gift_card_hash
                  # store_credit_call =  ShopifyAPI::GiftCard.find(:all)
                  single_store_credit_call = ShopifyAPI::GiftCard.create(gift_card_hash)
                  # single_store_credit_call = JSON.parse '{ "code": "shhncddgbardihs", "currency": "AUD", "customer_id": 2141628203117, "balance": "130.90", "initial_value": "130.90", "note": "Order No: 1004 - TOO SHORT", "id": 185868222573, "created_at": "2019-08-20T08:21:17-04:00", "updated_at": "2019-08-20T08:21:17-04:00", "disabled_at": null, "line_item_id": null, "api_client_id": 3041177, "user_id": null, "expires_on": null, "template_suffix": null, "last_characters": "dihs", "order_id": null }'
                  single_store_credit_call_errors = single_store_credit_call.errors #Hash.new
                  store_credit_call[line_item.sku] = single_store_credit_call;
                  store_credit_call_error[line_item.sku] = single_store_credit_call_errors # single_store_credit_call.errors
                  # Start: Save data to refund details and refund details api table
                  refund_datails_data = Hash.new
                  refund_datails_api_data = Hash.new
                  refund_datails_data['shop_id'] = get_shop_data['id']
                  refund_datails_data['sp_customer_id'] = order_data.customer.id
                  refund_datails_data['sp_order_id'] = order_data.id
                  refund_datails_data['sp_product_id'] = item['ShopifyOrderProductId']
                  refund_datails_data['sp_order_no'] = order_data.name
                  refund_datails_data['sp_product_sku'] = item['ItemSku']
                  refund_datails_data['sp_gift_card_code'] = gift_card_code
                  refund_datails_data['refund_type'] = 2
                  if single_store_credit_call_errors.empty?
                    refund_status = 1
                    status_message = 'Successfully Assigned Gift Card.'
                  else
                    refund_status = 0
                    status_message = 'Error in Gift Card.'
                  end
                  refund_datails_data['refund_status'] = refund_status
                  refund_datails_data['status_message'] = status_message
                  refund_datails_data['sp_order_line_item_id'] = item['ShopifyOrderLineItemId']
                  refund_datails_data['sp_refund_id'] = ''
                  refund_datails_data['gift_card_amount'] = gift_card_amount
                  # unless single_store_credit_call.id.nil?
                  if single_store_credit_call_errors.empty?
                    refund_datails_data['sp_gift_card_id'] = single_store_credit_call.id #single_store_credit_call["id"]
                  else 
                    refund_datails_data['sp_gift_card_id'] = ''
                  end
                  refund_datails_data_save = RefundDetail.create(refund_datails_data)

                  refund_datails_api_data['shop_id'] = get_shop_data['id']
                  refund_datails_api_data['refund_detail_id'] = refund_datails_data_save.id
                  refund_datails_api_data['refund_request'] = gift_card_hash.to_json
                  refund_datails_api_data['refund_response'] = single_store_credit_call.to_json
                  refund_datails_api_data['refund_error'] = single_store_credit_call.errors.to_json
                  refund_datails_api_data['refund_type'] = 1
                  refund_datails_api_data['refund_status'] = refund_status
                  refund_datails_api_data_save = RefundDetailApiLog.create(refund_datails_api_data)
                  # End: Save data to refund details and refund details api table
                end
                # render :json => store_credit_call
                gift_card_arr.push(gift_card_hash)
              else
                store_credit_call["Error"] = "Can't assign gift card more than purchased quantity."
                store_credit_call_error["Error"] = "Can't assign gift card more than purchased quantity."
              end
            end
          end
        end
      else
        store_credit_call["Error"] = "Private App data not available."
        store_credit_call_error["Error"] = "Private App data not available."
      end
      @response["Success"] = 1
      @response["Type"] = 'gift_card'
      @response["Message"] = "Called Gift Card Admin API."
      @response["Data"] = store_credit_call
      @response["Error"] = store_credit_call_error
      # render :json => gift_card_arr
      # Apply Refund to The Customer
    elsif refund == 1
      refund_order_call = Hash.new
      refund_hash = Hash.new
      # refund_hash['restock'] = false
      refund_hash['order_id'] = order_data.id
      refund_hash['note'] = params[:ReturnReason]
      if is_return_shipping_fee == 1
        shipping = Hash["full_refund" => true]
      else
        shipping = Hash["full_refund" => false]
      end
      refund_hash['shipping'] = shipping
      j=0;
      refund_line_items = Array.new
      params[:RefundItems].each do |item|
        temp_line = Hash.new
        temp_line['line_item_id'] = item['ShopifyOrderLineItemId']
        temp_line['quantity'] = item['ItemQuantity']
        # temp_line['restock_type'] = false
        refund_line_items.push(temp_line);
        j += 1
      end
      refund_hash['refund_line_items'] = refund_line_items
      refund_hash['currency'] = order_data.currency
      refund_hash['notify'] = true
      # render :json => refund_hash
      refund_order_call = ShopifyAPI::Refund.create(refund_hash); # main call
      # render :json => refund_order_call

      # refund_datails_data = Hash.new
      # Start: Save data to refund details and refund details api table
      params[:RefundItems].each do |item|
        refund_datails_data = Hash.new
        refund_datails_api_data = Hash.new
        refund_datails_data['shop_id'] = get_shop_data['id']
        refund_datails_data['sp_customer_id'] = order_data.customer.id
        refund_datails_data['sp_order_id'] = order_data.id
        refund_datails_data['sp_product_id'] = item['ShopifyOrderProductId']
        refund_datails_data['sp_order_no'] = order_data.name
        refund_datails_data['sp_product_sku'] = item['ItemSku']
        refund_datails_data['sp_gift_card_code'] = ''
        refund_datails_data['refund_type'] = 1
        if refund_order_call.errors.empty?
          refund_status = 1
          status_message = 'Successfully Refunded'
        else
          refund_status = 0
          status_message = 'Error in Refund'
        end
        refund_datails_data['refund_status'] = refund_status
        refund_datails_data['status_message'] = status_message
        refund_datails_data['sp_order_line_item_id'] = item['ShopifyOrderLineItemId']
        if refund_order_call.errors.empty?
          refund_order_call.refund_line_items.each do |refund_line_item|
            if refund_line_item.line_item_id == item['ShopifyOrderLineItemId']
              refund_datails_data['sp_refund_id'] = refund_line_item.id
            end
          end
        else
          refund_datails_data['sp_refund_id'] = ''
        end
        refund_datails_data['gift_card_amount'] = ''
        refund_datails_data['sp_gift_card_id'] = ''
        refund_datails_data_save = RefundDetail.create(refund_datails_data)

        refund_datails_api_data['shop_id'] = get_shop_data['id']
        refund_datails_api_data['refund_detail_id'] = refund_datails_data_save.id
        refund_datails_api_data['refund_request'] = refund_hash.to_json
        refund_datails_api_data['refund_response'] = refund_order_call.to_json
        refund_datails_api_data['refund_error'] = refund_order_call.errors.to_json
        refund_datails_api_data['refund_type'] = 1
        refund_datails_api_data['refund_status'] = refund_status
        refund_datails_api_data_save = RefundDetailApiLog.create(refund_datails_api_data)
      end
      # End: Save data to refund details and refund details api table
      
      # refund_order_call = ShopifyAPI::Refund.calculate({ :shipping => { :amount => 0 } }, :params => {:order_id => order_data.id});
      # refund_order_data = ShopifyAPI::Order.find(order_data.id)
      # refund_params = {:restock => false, :note => "ARRIVED TOO LATE", :shipping => {:full_refund => false}, :refund_line_items => [{:line_item_id => 2218568253503, :quantity => 1}], :currency => "INR", :notify => true}
      # refund_order_call = ShopifyAPI::Refund.create( :order_id => order_data.id, :restock => false, :note => "ARRIVED TOO LATE", :shipping => {:full_refund => false}, :refund_line_items => [{:line_item_id => 2218568253503, :quantity => 1}], :currency => "INR", :notify => true );
      @response["Success"] = 1
      @response["Type"] = 'refund'
      @response["Message"] = "Called Order Refund Admin API."
      @response["Data"] = refund_order_call
      @response["Errors"] = refund_order_call.errors
    else
      @response["Success"] = 0
      #@response["Type"] = ''
      @response["Message"] = "Something went wrong!"
    end
    # Response data
    render :json => @response
    # render :json => refund_order_call.errors
#=end

  end

  # Check gift card available or not
  def check_gift_card_available(shop_id, sp_order_id, sp_order_line_item_id, order_data)
    refund_details = RefundDetail.select("id").where(shop_id: shop_id, sp_order_id: sp_order_id, sp_order_line_item_id: sp_order_line_item_id, refund_type: "2", refund_status: "1").find_all
    refund_details_count = refund_details.size
    return_val = 1
    if refund_details_count > 0
      order_data.line_items.each do |line_item|
        if line_item.id == sp_order_line_item_id 
          if refund_details_count >= line_item.quantity
            return_val = 0
          end
        end
      end
    end
    return return_val
  end

  # This action is for test
  def test
    @params = params
    # @shop = defined?(ShopifyAPI);
    # @order_no = params[:order_no]
    # @shop_url = params[:shop]
    shop_url = 'gozti.myshopify.com';
    # get shop data by shop URL
    get_shop_data = Shop.where(shopify_domain: shop_url).first
    # Create Shopify API session
    session = ShopifyAPI::Session.new(domain: get_shop_data['shopify_domain'], token: get_shop_data['shopify_token'], api_version: "2019-04")
    # session = ShopifyAPI::Session.new(domain: "queuefirst.myshopify.com", token: "4a6fdfd48b3d17639994e2f39d9bd8bd", api_version: "2019-04")
    # products = ShopifyAPI::Session.temp("queuefirst.myshopify.com", "4a6fdfd48b3d17639994e2f39d9bd8bd") { ShopifyAPI::Product.find(:all) }
    ShopifyAPI::Base.activate_session(session)

    # @gift_card = ShopifyAPI::GiftCard.create()
    # @gift_card = ShopifyAPI::GiftCard.find(185757892671)
    @gift_card = ShopifyAPI::GiftCard.find(:all)
    render :json => @gift_card

=begin
    @products = ShopifyAPI::Product.find(:all, {id: 1892575608895})
    # @products_metafield = ShopifyAPI::Metafield.find(:all, :params=>{:resource => "products", :resource_id => 1892575608895})
    @products_metafield = ShopifyAPI::Metafield.find(:all)
    # Render JSON
    # render :json => @products_metafield

    @shop = ShopifyAPI::Shop.current

    # Get all products
    @products = ShopifyAPI::Product.find(:all)

    # Get all orders
    @orders = ShopifyAPI::Order.find(:all)

    # Get all orders
    @orders = ShopifyAPI::Order.find(:all)

    # Fetch all countries data
    @all_countries = ShopifyAPI::Country.find(:all, params: {}).to_json

    # Specific order from shopify store
    @specific_order = ShopifyAPI::Order.find(:all, params: { order_number: '1001', :limit => 1, :order => "created_at ASC"}).to_json
    # render :json => @specific_order

    # Shops list from database
    @shops = Shop.all.to_json

    # Specific shop from database
    @specific_shop = Shop.where(shopify_domain: "queuefirst.myshopify.com").first.to_json

    # Get shop data
    @get_shop_data = Shop.where(shopify_domain: "queuefirst.myshopify.com").first
=end

  end
  
  # Test private app with gift card
  def test_one
	# ShopifyAPI::Base.clear_session

    shopify_shop_url = 'loot-mart-store.myshopify.com';
    shopify_private_app_api_key = '3c38dfedbcd441f93ced0241cd571c5a'
    shopify_private_app_api_password = 'c88b7cea29069fc33944a20a0caf5eec'

=begin
    private_appshop_url = "https://#{shopify_private_app_api_key}:#{shopify_private_app_api_password}@#{shopify_shop_url}/admin"
    ShopifyAPI::Base.site = private_appshop_url
	ShopifyAPI::Base.api_version = '2019-04'
=end

	  shop_url = 'loot-mart-store.myshopify.com';
    # get shop data by shop URL
    get_shop_data = Shop.where(shopify_domain: shop_url).first
    # Create Shopify API session
    session = ShopifyAPI::Session.new(domain: get_shop_data['shopify_domain'], token: get_shop_data['shopify_token'], api_version: "2019-04")
    # session = ShopifyAPI::Session.new(domain: "queuefirst.myshopify.com", token: "4a6fdfd48b3d17639994e2f39d9bd8bd", api_version: "2019-04")
    # products = ShopifyAPI::Session.temp("queuefirst.myshopify.com", "4a6fdfd48b3d17639994e2f39d9bd8bd") { ShopifyAPI::Product.find(:all) }
    ShopifyAPI::Base.activate_session(session)
    @order = ShopifyAPI::Order.find('1328371302509')
    
    private_appshop_domain = "#{shopify_private_app_api_key}:#{shopify_private_app_api_password}@#{shopify_shop_url}"
    ShopifyAPI::Session.temp(domain: private_appshop_domain, token: shopify_private_app_api_password, api_version: ShopifyApp.configuration.api_version) do
      @response =  ShopifyAPI::GiftCard.find(:all)
      render :json =>  @order
    end
    # render :json =>  @response
    # ShopifyAPI::Shop.current
    # @response = ShopifyAPI::GiftCard.find(:all)
    # render :json =>  @response
    # @gift_card = ShopifyAPI::GiftCard.find(185757892671)
    # render :json => @gift_card
  end
  
  def test_get_order(order_no)
	  shop_url = 'loot-mart-store.myshopify.com';
    # get shop data by shop URL
    get_shop_data = Shop.where(shopify_domain: shop_url).first
    # Create Shopify API session
    session = ShopifyAPI::Session.new(domain: get_shop_data['shopify_domain'], token: get_shop_data['shopify_token'], api_version: "2019-04")
    # session = ShopifyAPI::Session.new(domain: "queuefirst.myshopify.com", token: "4a6fdfd48b3d17639994e2f39d9bd8bd", api_version: "2019-04")
    # products = ShopifyAPI::Session.temp("queuefirst.myshopify.com", "4a6fdfd48b3d17639994e2f39d9bd8bd") { ShopifyAPI::Product.find(:all) }
    ShopifyAPI::Base.activate_session(session)
	  # Get all orders
    @order = ShopifyAPI::Order.find('1328371302509')
	  # return order data
	  return @order
  end
  
  # Test private app with gift card add
  def test_two
    shopify_shop_url = 'loot-mart-store.myshopify.com';
    shopify_private_app_api_key = '3c38dfedbcd441f93ced0241cd571c5a'
    shopify_private_app_api_password = 'c88b7cea29069fc33944a20a0caf5eec'

    private_appshop_url = "https://#{shopify_private_app_api_key}:#{shopify_private_app_api_password}@#{shopify_shop_url}/admin"
    ShopifyAPI::Base.site = private_appshop_url
    ShopifyAPI::Base.api_version = '2019-04'

	# Get all orders
    #order_data = ShopifyAPI::Order.find('1328371302509')
	#render :json => order_data	
	
# =begin
	order_data = ShopifyAPI::Order.find('1328371302509')
	# order_data = test_get_order('1328371302509')

	store_credit_call = Hash.new
	store_credit_call_arr = Array.new
	gift_card_arr = Array.new
	order_data.line_items.each do |line_item|
		# params[:RefundItems].each do |item|
		  # if item['ShopifyOrderLineItemId'] == line_item.id
			gift_card_hash = Hash.new
			number = 18
			charset = Array('A'..'Z')
			gift_card_code = Array.new(number) { charset.sample }.join
			gift_card_hash['order_id'] = order_data.id
			gift_card_hash['line_item_id'] = line_item.id
			gift_card_hash['customer_id'] = order_data.customer.id
			# gift_card_hash['code'] = gift_card_code
			gift_card_hash['currency'] = order_data.currency
			line_item_amount = line_item.pre_tax_price;
			line_item_tax_amount = 0
			line_item.tax_lines.each do |tax_amount|
			  line_item_tax_amount = line_item_tax_amount.to_f + tax_amount.price.to_f
			end
			gift_card_hash['balance'] = line_item_amount.to_f + line_item_tax_amount.to_f
			gift_card_hash['initial_value'] = line_item_amount.to_f + line_item_tax_amount.to_f
			gift_card_hash['note'] = ""
			# gift_card_hash['api_client_id'] = '187841937517'
			# gift_card_hash['api_client_id'] = nil
			
			# render :json => gift_card_hash
			store_credit_call = ShopifyAPI::GiftCard.create(gift_card_hash)
			render :json => store_credit_call
			store_credit_call_arr.push(store_credit_call);
			# render :json => store_credit_call
			gift_card_arr.push(gift_card_hash)
		  # end
		# end
	end
	
	# render :json => store_credit_call_arr

# =end

  end
  
  # Test get order data
  def test_three
	  shop_url = 'loot-mart-store.myshopify.com';
    # get shop data by shop URL
    get_shop_data = Shop.where(shopify_domain: shop_url).first
    # Create Shopify API session
    session = ShopifyAPI::Session.new(domain: get_shop_data['shopify_domain'], token: get_shop_data['shopify_token'], api_version: "2019-04")
    # session = ShopifyAPI::Session.new(domain: "queuefirst.myshopify.com", token: "4a6fdfd48b3d17639994e2f39d9bd8bd", api_version: "2019-04")
    # products = ShopifyAPI::Session.temp("queuefirst.myshopify.com", "4a6fdfd48b3d17639994e2f39d9bd8bd") { ShopifyAPI::Product.find(:all) }
    ShopifyAPI::Base.activate_session(session)

=begin
	  shopify_shop_url = 'loot-mart-store.myshopify.com';
    shopify_private_app_api_key = '3c38dfedbcd441f93ced0241cd571c5a'
    shopify_private_app_api_password = 'c88b7cea29069fc33944a20a0caf5eec'

    private_appshop_url = "https://#{shopify_private_app_api_key}:#{shopify_private_app_api_password}@#{shopify_shop_url}/admin"
    ShopifyAPI::Base.site = private_appshop_url
    ShopifyAPI::Base.api_version = '2019-04'
=end

	# Get all orders
    @orders = ShopifyAPI::Order.find('1328371302509')
    render :json => @orders	
    # render :json => ShopifyApp.configuration.api_version
  end

  def test_order_data
    shop_url = 'lady-apparel.myshopify.com';
    # get shop data by shop URL
    get_shop_data = Shop.where(shopify_domain: shop_url).first
    # Create Shopify API session
    session = ShopifyAPI::Session.new(domain: get_shop_data['shopify_domain'], token: get_shop_data['shopify_token'], api_version: "2019-04")
    # session = ShopifyAPI::Session.new(domain: "queuefirst.myshopify.com", token: "4a6fdfd48b3d17639994e2f39d9bd8bd", api_version: "2019-04")
    # products = ShopifyAPI::Session.temp("queuefirst.myshopify.com", "4a6fdfd48b3d17639994e2f39d9bd8bd") { ShopifyAPI::Product.find(:all) }
    ShopifyAPI::Base.activate_session(session)
	  # Get all orders
    @order = ShopifyAPI::Order.find('1154707423278')
    # return order data
    render :json =>  @order
  end


end