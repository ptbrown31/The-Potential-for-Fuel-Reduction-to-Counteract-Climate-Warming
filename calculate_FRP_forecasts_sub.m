close all 
clear all

%addpath '';

%% what this program needs to run

% 1) long time array with antecedent hours that starts with 4variable-forecast
% 2) shorter time array with antecedent hours that starts with 3variable-forecast
% 3) the landfire variables on the wrf grid in read_landfire_2022_fuel_for_viirs_all_detect.mat
% 4) the landfire variables on the wrf grid that are altered to represent fuel treatement in read_landfire_2022_fuel_for_viirs_all_detect_treatment_scen.mat
% 5) future temperature change from CORDEX (that are function of space and month of year) in read_org_background_temp_cordex_delta_for_viirs.mat
% 6) the pre-trained nueral network and decision tree models in train_and_validate_multiple_model_hyper_optimization.mat

% 7) costom function calc_humidity_variables_2
% 8) costom function calc_dfm

%% get pathnames for forecast files

filename_base_path = pwd;

filename_all_hours_dir = dir(strcat(filename_base_path,'/4var*'));
filename_forecast_hours_dir = dir(strcat(filename_base_path,'/3var*'));

%% make spatial dimension 1d and only contain burnable land

load(strcat(filename_base_path,'/read_landfire_2022_fuel_for_viirs_all_detect.mat'),...
    'wrf_lat_2d',...
    'wrf_lon_2d',...
    'fuel_model_attribute_var_names',...
    'all_land_var_names',...
    'all_land_vars_wrf_grid_map')

all_land_vars_wrf_grid_map_pre_treatment = all_land_vars_wrf_grid_map;

load(strcat(filename_base_path,'/read_landfire_2022_fuel_for_viirs_all_detect_treatment_scen.mat'),...
    'all_land_vars_wrf_grid_map')

all_land_vars_wrf_grid_map_post_treatment = all_land_vars_wrf_grid_map;

clear all_land_vars_wrf_grid_map

% size(all_land_vars_wrf_grid_map)
%    396   480    22

% all_land_var_names = ["Elevation (m)",...                              1
%                       "Slope (degrees)",...                            2
%                       "Aspect (degrees?)",...                          3
%                       "Scott & Burgan Coded Value",...                 4
%                       "1-hr dead (tons/acre)",...                      5
%                       "10-hr dead (tons/acre)",...                     6
%                       "100-hr dead (tons/acre)",...                    7
%                       "Total Dead (tons/acre)",...                     8
%                       "Live herb (tons/acre)",...                      9
%                       "Live woody (tons/acre)",...                     10
%                       "Total Live (tons/acre)",...                     11
%                       "Total Surface (tons/acre)",...	                 12
%                       "Fuel Bed Depth (ft)",...                        13
%                       "Scott & Burgan Broad Cat",...                   14
%                       "Scott & Burgan Rate-of-Spread (Ch/h)",...       15
%                       "Scott & Burgan Flame Length (ft)",...           16
%                       "Canopy Cover (%)",...                           17
%                       "Canopy Height (m)",...                          18
%                       "Canopy Base Height (m)",...                     19
%                       "Canopy Bulk Density (kg/m^3)",...               20
%                       "Canopy Fuel Load (kg/m^2)",...                  21
%                       "Surface + Canopy Fuel Load (tons/acre)"];       22

good_pixel_map = NaN(size(wrf_lat_2d));

good_fuel_lin_inds = find(squeeze(all_land_vars_wrf_grid_map_pre_treatment(:,:,12)) > 2);
[good_fuel_inds_x, good_fuel_inds_y] = find(squeeze(all_land_vars_wrf_grid_map_pre_treatment(:,:,12)) > 2);

%how much does this reduce the size?

length(good_fuel_lin_inds)./numel(wrf_lat_2d)

all_land_vars_wrf_pre_treatment_linear = NaN(length(good_fuel_lin_inds),length(all_land_var_names));
all_land_vars_wrf_post_treatment_linear = NaN(length(good_fuel_lin_inds),length(all_land_var_names));

for land_var_i = 1:length(all_land_var_names)

    %pre-treatment
        grid_map_now = squeeze(all_land_vars_wrf_grid_map_pre_treatment(:,:,land_var_i));
        all_land_vars_wrf_pre_treatment_linear(:,land_var_i) = grid_map_now(good_fuel_lin_inds);

    %post-treatment
        grid_map_now = squeeze(all_land_vars_wrf_grid_map_post_treatment(:,:,land_var_i));
        all_land_vars_wrf_post_treatment_linear(:,land_var_i) = grid_map_now(good_fuel_lin_inds);
end

%% read in time info and create matlab datetime arrays

    time_file_forecast_time = ncread(strcat(filename_base_path,'/',filename_forecast_hours_dir.name),"Times");
    time_file_all_time = ncread(strcat(filename_base_path,'/',filename_all_hours_dir.name),"Times");

    num_hours_forecast = size(time_file_forecast_time,2);
    num_hours_all = size(time_file_all_time,2);

    last_hour_date_forecast = datetime(str2double(strcat(time_file_forecast_time(1,end),time_file_forecast_time(2,end),time_file_forecast_time(3,end),time_file_forecast_time(4,end))),...
                                    str2double(strcat(time_file_forecast_time(6,end),time_file_forecast_time(7,end))),...
                                    str2double(strcat(time_file_forecast_time(9,end),time_file_forecast_time(10,end))),...
                                    str2double(strcat(time_file_forecast_time(12,end),time_file_forecast_time(13,end))),...
                                    0,...
                                    0);

    last_hour_date_all = datetime(str2double(strcat(time_file_all_time(1,end),time_file_all_time(2,end),time_file_all_time(3,end),time_file_all_time(4,end))),...
                                    str2double(strcat(time_file_all_time(6,end),time_file_all_time(7,end))),...
                                    str2double(strcat(time_file_all_time(9,end),time_file_all_time(10,end))),...
                                    str2double(strcat(time_file_all_time(12,end),time_file_all_time(13,end))),...
                                    0,...
                                    0);

    if last_hour_date_all ~= last_hour_date_forecast

        disp('times are not lined up between the two files!')

    end

    %create matlab datetime arrays

    datetime_forecast_hours = last_hour_date_forecast-hours(num_hours_forecast)+hours(1):hours(1):last_hour_date_forecast;
    datetime_all_hours = last_hour_date_all-hours(num_hours_all)+hours(1):hours(1):last_hour_date_all;

%% read in gridded variables long

    forecast_file_long_info = ncinfo(strcat(filename_base_path,'/',filename_all_hours_dir.name));    

    forecast_file_long_read_in_var_names = ["T2",...
                                            "PSFC",...
                                            "Q2",...
                                            "PREC_ACC_NC"];   

    forecast_file_long_var_names = ["Temperature (K)",...
                                    "Surface Pressure (Pa)",...
                                    "Surface Water Vapor Mixing Ratio (kg/kg)",...
                                    "Precipitation (mm/hr)"];

    linear_fund_vars_for_dfm = NaN(length(good_fuel_lin_inds),num_hours_all,length(forecast_file_long_var_names));

    for fund_vars_i = 1:length(forecast_file_long_read_in_var_names)

        gridded_file = ncread(strcat(filename_base_path,'/',filename_all_hours_dir.name),forecast_file_long_read_in_var_names(fund_vars_i));

        for hours_i = 1:length(datetime_all_hours)

            gridded_file_this_hour = squeeze(gridded_file(:,:,hours_i));

            linear_fund_vars_for_dfm(:,hours_i,fund_vars_i) = gridded_file_this_hour(good_fuel_lin_inds);

        end

        % disp('loading long variables')
        % fund_vars_i./length(forecast_file_long_read_in_var_names)

    end

    clear gridded_file

%% place different climate model temperature offsets on the grid

load(strcat(filename_base_path,'/read_org_background_temp_cordex_delta_for_viirs.mat'),...
'wrf_lat_2d',...
'wrf_lon_2d',...
'all_cordex_deltas_wrf_grid',...
'months',...
'projection_timeframe',...
'emissions_scenario')

% size(all_cordex_deltas_wrf_grid)
%    396   480    12     2 (time)     2 (emissions)
%all_cordex_deltas(:,:,month_i,projections_timeframe_i,emissions_scenario_i)

% projection_timeframe'
%     {'Medium Term (2041-2060)'}
%     {'Long Term (2081-2100)'  }

% emissions_scenario'
%     {'RCP2.6'}
%     {'RCP4.5'}

climate_scenario_names = {'Today',...
                          '2050 - SSP1-2.6',...
                          '2050 - SSP2-4.5'};

all_climate_model_linear_temperatures = NaN(length(good_fuel_lin_inds),length(datetime_all_hours),length(climate_scenario_names));

%march through lags
for hours_i = 1:length(datetime_all_hours)

%find the right month of the year
    month_of_year = month(datetime_all_hours(hours_i));

    linear_temp_at_this_lag = squeeze(linear_fund_vars_for_dfm(:,hours_i,1));

    grid_2050_diff_from_today_rcp26 = squeeze(all_cordex_deltas_wrf_grid(:,:,month_of_year,1,1));
    grid_2050_diff_from_today_rcp45 = squeeze(all_cordex_deltas_wrf_grid(:,:,month_of_year,1,2));

    linear_2050_diff_from_today_rcp26 = grid_2050_diff_from_today_rcp26(good_fuel_lin_inds);
    linear_2050_diff_from_today_rcp45 = grid_2050_diff_from_today_rcp45(good_fuel_lin_inds);

    all_climate_model_linear_temperatures(:,hours_i,1) = linear_temp_at_this_lag;
    all_climate_model_linear_temperatures(:,hours_i,2) = linear_temp_at_this_lag + linear_2050_diff_from_today_rcp26;
    all_climate_model_linear_temperatures(:,hours_i,3) = linear_temp_at_this_lag + linear_2050_diff_from_today_rcp45;

end

%% make moisture arrays

RH_array = NaN(size(all_climate_model_linear_temperatures));

P_in_KPa_2d = squeeze(linear_fund_vars_for_dfm(:,:,2))./1000;
r_in_kg_per_kg_2d = squeeze(linear_fund_vars_for_dfm(:,:,3));

    for temp_scenarios_i = 1:length(climate_scenario_names)
    
        T_in_K_2d = squeeze(all_climate_model_linear_temperatures(:,:,temp_scenarios_i));
    
        [VPD_2d,es_2d,e_2d,RH_2d] = calc_humidity_variables_2(T_in_K_2d-273.15,P_in_KPa_2d,r_in_kg_per_kg_2d);

        RH_array(:,:,temp_scenarios_i) = RH_2d;

        % disp('making RH array')
        % temp_scenarios_i./length(climate_scenario_names)
    end

    RH_array(RH_array <= 0) = 0;
    RH_array(RH_array >= 100) = 100;

    clear P_in_KPa_2d
    clear r_in_kg_per_kg_2d
    clear T_in_K_2d
    clear VPD_2d
    clear es_2d
    clear e_2d
    clear RH_2d
    clear Td_2d

%% make DFM arrays

fuel_moisture_predictor_variables = {'1 hour DFM',...,...
                                     '10 hour DFM',...
                                     '100 hour DFM',...
                                     '1000 hour DFM'};

DFM_values = [1 10 100 1000];

hours_needed = 6*24+3*DFM_values;

start_hour_ind = length(datetime_all_hours) - hours_needed + 1;

DFM_array_1_hr = NaN(length(good_fuel_lin_inds),hours_needed(1),length(climate_scenario_names));
DFM_array_10_hr = NaN(length(good_fuel_lin_inds),hours_needed(2),length(climate_scenario_names));
DFM_array_100_hr = NaN(length(good_fuel_lin_inds),hours_needed(3),length(climate_scenario_names));
DFM_array_1000_hr = NaN(length(good_fuel_lin_inds),hours_needed(4),length(climate_scenario_names));

for dfm_hr_i = 1:length(fuel_moisture_predictor_variables)

    precip_mm_hourly_time_series_sub = squeeze(linear_fund_vars_for_dfm(:,start_hour_ind(dfm_hr_i):end,4));

    for temp_scenarios_i = 1:length(climate_scenario_names)

        T_K_hourly_time_series_sub = squeeze(all_climate_model_linear_temperatures(:,start_hour_ind(dfm_hr_i):end,temp_scenarios_i));
    
        RH_perc_hourly_time_series_sub = squeeze(RH_array(:,start_hour_ind(dfm_hr_i):end,temp_scenarios_i));
    
        %subselect based on hours neccesary
    
        for linear_loc_i = 1:length(good_fuel_lin_inds)
    
                 DFM_hour = DFM_values(dfm_hr_i);
    
                 [DFM_hourly_time_series] = calc_dfm(T_K_hourly_time_series_sub(linear_loc_i,:),...
                                                     RH_perc_hourly_time_series_sub(linear_loc_i,:),...
                                                     precip_mm_hourly_time_series_sub(linear_loc_i,:),...
                                                     DFM_hour);

                 if dfm_hr_i == 1; DFM_array_1_hr(linear_loc_i,:,temp_scenarios_i) = DFM_hourly_time_series; end    
                 if dfm_hr_i == 2; DFM_array_10_hr(linear_loc_i,:,temp_scenarios_i) = DFM_hourly_time_series; end
                 if dfm_hr_i == 3; DFM_array_100_hr(linear_loc_i,:,temp_scenarios_i) = DFM_hourly_time_series; end
                 if dfm_hr_i == 4; DFM_array_1000_hr(linear_loc_i,:,temp_scenarios_i) = DFM_hourly_time_series; end
    
    
        end

        disp('making dfm arrays')
        dfm_hr_i./length(fuel_moisture_predictor_variables)
        temp_scenarios_i./length(climate_scenario_names)

    end
end

clear T_K_hourly_time_series_sub
clear RH_perc_hourly_time_series_sub
clear precip_mm_hourly_time_series_sub

%% limit everything to forecast hours

RH_array = squeeze(RH_array(:,end-num_hours_forecast+1:end,:));

precip_array = squeeze(linear_fund_vars_for_dfm(:,end-num_hours_forecast+1:end,4));
clear linear_fund_vars_for_dfm;

temperature_array = all_climate_model_linear_temperatures(:,end-num_hours_forecast+1:end,:);
clear all_climate_model_linear_temperatures

DFM_array_1_hr = DFM_array_1_hr(:,end-num_hours_forecast+1:end,:);
DFM_array_10_hr = DFM_array_10_hr(:,end-num_hours_forecast+1:end,:);
DFM_array_100_hr = DFM_array_100_hr(:,end-num_hours_forecast+1:end,:);
DFM_array_1000_hr = DFM_array_1000_hr(:,end-num_hours_forecast+1:end,:);

%% read in additional gridded variables over forecast period

    forecast_file_short_info = ncinfo(strcat(filename_base_path,'/',filename_forecast_hours_dir.name));

    forecast_file_short_read_in_var_names = ["SWDOWN",...
                                             "UST",...
                                             "UV10"];

    forecast_file_short_var_names = ["Shortwave Radiation (W/m^2)",...
                                     "Shear Velocity (m/s)",...
                                     "Wind Speed (m/s)"];

    linear_forecast_vars = NaN(length(good_fuel_lin_inds),num_hours_forecast,length(forecast_file_short_var_names));

    for forecast_vars_i = 1:length(forecast_file_short_read_in_var_names)

        gridded_file = ncread(strcat(filename_base_path,'/',filename_forecast_hours_dir.name),forecast_file_short_read_in_var_names(forecast_vars_i));

        for hours_i = 1:length(datetime_forecast_hours)

            gridded_file_this_hour = squeeze(gridded_file(:,:,hours_i));

            linear_forecast_vars(:,hours_i,forecast_vars_i) = gridded_file_this_hour(good_fuel_lin_inds);

        end
    end

    clear gridded_file

    wind_array = linear_forecast_vars(:,:,3);

%% load models to make predictions 

 load(strcat(filename_base_path,'/train_and_validate_multiple_model_hyper_optimization.mat'),...
     'all_predictor_variables_var_names',...
     'input_predictor_variables_var_names',...
     'nn_model_collection',...
     'tree_model_collection')

 %cut number of models for time
 
 num_each_models_to_use = 5;

 nn_model_collection = nn_model_collection(1:num_each_models_to_use);
 tree_model_collection = tree_model_collection(1:num_each_models_to_use);

 num_models_to_train = length(nn_model_collection)+length(tree_model_collection);

% all_predictor_variables_var_names'
%     {'Elevation (m)'                              } 1
%     {'Aspect (degrees)'                           } 2
%     {'Slope (degrees)'                            } 3 * 1
%     {'Scott & Burgan Coded Value'                 } 4
%     {'1-hr dead (tons/acre)'                      } 5 * 2
%     {'10-hr dead (tons/acre)'                     } 6 * 3
%     {'100-hr dead (tons/acre)'                    } 7 * 4
%     {'Total Dead (tons/acre)'                     } 8
%     {'Live herb (tons/acre)'                      } 9 * 5
%     {'Live woody (tons/acre)'                     } 10 * 6
%     {'Total Live (tons/acre)'                     } 11
%     {'Total Surface (tons/acre)'                  } 12
%     {'Fuel Bed Depth (ft)'                        } 13 * 7
%     {'Scott & Burgan Broad Cat'                   } 14
%     {'Scott & Burgan Rate-of-Spread (Ch/h)'       } 15
%     {'Scott & Burgan Flame Length (ft)'           } 16
%     {'Canopy Cover (%)'                           } 17 * 8
%     {'Canopy Height (m)'                          } 18 * 9
%     {'Canopy Base Height (m)'                     } 19 * 10
%     {'Canopy Bulk Density (kg/m^3)'               } 20 * 11
%     {'Canopy Fuel Load (kg/m^2)'                  } 21
%     {'Surface + Canopy Fuel Load (tons/acre)'     } 22
%     {'1 hour DFM'                                 } 23 * 12
%     {'10 hour DFM'                                } 24 * 13
%     {'100 hour DFM'                               } 25 * 14
%     {'1000 hour DFM'                              } 26 * 15
%     {'Temperature (K)'                            } 27
%     {'Surface Downard Shortwave Radiation (W/m^2)'} 28
%     {'Shear Velocity (m/s)'                       } 29
%     {'24-hr Precipitation (mm/hr)'                } 30
%     {'Wind Speed (m/s)'                           } 31 * 16
%     {'dry 1hr dead fuel load'                     } 32
%     {'dry 10hr dead fuel load'                    } 33
%     {'dry 100hr dead fuel load'                   } 34

 %% make land predictor values have the same value for each hour

 land_predictor_input_indices = [3 5 6 7 9 10 13 17 18 19 20];

 all_land_vars_wrf_pre_treatment_linear_input = all_land_vars_wrf_pre_treatment_linear(:,land_predictor_input_indices);
 all_land_vars_wrf_post_treatment_linear_input = all_land_vars_wrf_post_treatment_linear(:,land_predictor_input_indices);

 all_land_vars_wrf_pre_treatment_linear_input_with_time = NaN(length(good_fuel_lin_inds),length(datetime_forecast_hours),length(land_predictor_input_indices));
 all_land_vars_wrf_post_treatment_linear_input_with_time = NaN(length(good_fuel_lin_inds),length(datetime_forecast_hours),length(land_predictor_input_indices));

 for hours_i = 1:length(datetime_forecast_hours)

     all_land_vars_wrf_pre_treatment_linear_input_with_time(:,hours_i,:) = all_land_vars_wrf_pre_treatment_linear_input;
     all_land_vars_wrf_post_treatment_linear_input_with_time(:,hours_i,:) = all_land_vars_wrf_post_treatment_linear_input;

 end

 %% make predictions

num_rows_predictor_matrix = length(good_fuel_lin_inds).*length(datetime_forecast_hours);

% climate_scenario_names = {'Today',...
%                           '2081-2100 - SSP1-2.6',...
%                           '2081-2100 - SSP2-4.5'};

% There are 5 total scenarios

% 1) Today                                                                  [temp scenario 1][no fuel treatment]
% 2) low emissions, with fuel treatement                                    [temp scenario 2][yes fuel treatment]
% 3) low emissions, no fuel treatement                                      [temp scenario 2][no fuel treatment]
% 4) high emissions, with fuel treatement                                   [temp scenario 3][yes fuel treatment]
% 5) high emissions, no fuel treatement                                     [temp scenario 3][no fuel treatment]

all_scenario_names = ["Today",...
                      "2050, RCP2.6 & fuel treatment",...
                      "2050, RCP2.6 & no fuel treatment",...
                      "2050, RCP4.5 & fuel treatment",...
                      "2050, RCP4.5 & no fuel treatment"];

forecast_vectors_for_each_ML_model = NaN(num_rows_predictor_matrix,num_models_to_train,length(all_scenario_names));

for all_scenario_i = 1:length(all_scenario_names)

    if all_scenario_i == 1 % Today [temp scenario 1][no fuel treatment]

        temp_scenarios_i = 1;
        all_land_vars_wrf_linear_input_with_time = all_land_vars_wrf_pre_treatment_linear_input_with_time;

    end
    if all_scenario_i == 2 % Low emissions, with fuel treatement [temp scenario 2][yes fuel treatment]

        temp_scenarios_i = 2;
        all_land_vars_wrf_linear_input_with_time = all_land_vars_wrf_post_treatment_linear_input_with_time;

    end
    if all_scenario_i == 3 % Low emissions, no fuel treatement [temp scenario 2][no fuel treatment]

        temp_scenarios_i = 2;
        all_land_vars_wrf_linear_input_with_time = all_land_vars_wrf_pre_treatment_linear_input_with_time;

    end
    if all_scenario_i == 4 % High emissions, with fuel treatement [temp scenario 3][yes fuel treatment]

        temp_scenarios_i = 3;
        all_land_vars_wrf_linear_input_with_time = all_land_vars_wrf_post_treatment_linear_input_with_time;

    end
    if all_scenario_i == 5 % High emissions, no fuel treatement [temp scenario 3][no fuel treatment]

        temp_scenarios_i = 3;
        all_land_vars_wrf_linear_input_with_time = all_land_vars_wrf_pre_treatment_linear_input_with_time;

    end
    
        %pull out the variables that vary with temp scenarios
    
            DFM_array_1_hr_this_scen = squeeze(DFM_array_1_hr(:,:,temp_scenarios_i));
            DFM_array_10_hr_this_scen = squeeze(DFM_array_10_hr(:,:,temp_scenarios_i));
            DFM_array_100_hr_this_scen = squeeze(DFM_array_100_hr(:,:,temp_scenarios_i));
            DFM_array_1000_hr_this_scen = squeeze(DFM_array_1000_hr(:,:,temp_scenarios_i));
    
            %assemble predictor array that matches what ML models expect
    
            input_predictor_matrix = [reshape(all_land_vars_wrf_linear_input_with_time(:,:,1),num_rows_predictor_matrix,1),...
                                      reshape(all_land_vars_wrf_linear_input_with_time(:,:,2),num_rows_predictor_matrix,1),...
                                      reshape(all_land_vars_wrf_linear_input_with_time(:,:,3),num_rows_predictor_matrix,1),...
                                      reshape(all_land_vars_wrf_linear_input_with_time(:,:,4),num_rows_predictor_matrix,1),...
                                      reshape(all_land_vars_wrf_linear_input_with_time(:,:,5),num_rows_predictor_matrix,1),...
                                      reshape(all_land_vars_wrf_linear_input_with_time(:,:,6),num_rows_predictor_matrix,1),...
                                      reshape(all_land_vars_wrf_linear_input_with_time(:,:,7),num_rows_predictor_matrix,1),...
                                      reshape(all_land_vars_wrf_linear_input_with_time(:,:,8),num_rows_predictor_matrix,1),...
                                      reshape(all_land_vars_wrf_linear_input_with_time(:,:,9),num_rows_predictor_matrix,1),...
                                      reshape(all_land_vars_wrf_linear_input_with_time(:,:,10),num_rows_predictor_matrix,1),...
                                      reshape(all_land_vars_wrf_linear_input_with_time(:,:,11),num_rows_predictor_matrix,1),...
                                      reshape(DFM_array_1_hr_this_scen,num_rows_predictor_matrix,1),...
                                      reshape(DFM_array_10_hr_this_scen,num_rows_predictor_matrix,1),...
                                      reshape(DFM_array_100_hr_this_scen,num_rows_predictor_matrix,1),...
                                      reshape(DFM_array_1000_hr_this_scen,num_rows_predictor_matrix,1),...
                                      reshape(linear_forecast_vars(:,:,3),num_rows_predictor_matrix,1)];
    
        for models_i = 1:num_models_to_train

            if models_i <= length(nn_model_collection)
            
               regressionModel = nn_model_collection{models_i};
        
               forecast_vectors_for_each_ML_model(:,models_i,all_scenario_i) = predict(regressionModel,input_predictor_matrix);

            end

            if models_i > length(nn_model_collection)
            
               regressionModel = tree_model_collection{models_i-length(nn_model_collection)};
        
               forecast_vectors_for_each_ML_model(:,models_i,all_scenario_i) = predict(regressionModel,input_predictor_matrix);

            end
    
           % all_scenario_i
           % models_i
        
        end
end

forecast_vectors_ML_model_median = squeeze(median(forecast_vectors_for_each_ML_model,2,"omitnan"));

%% unwrap into space-time and then lon-lat-time

forecast_FRP_given_fire = NaN(size(wrf_lat_2d,1),size(wrf_lat_2d,2),num_hours_forecast,length(all_scenario_names));

for all_scenario_i = 1:length(all_scenario_names)

    forecast_vectors_ML_model_median_this_scen = forecast_vectors_ML_model_median(:,all_scenario_i);

    forecast_FRP_given_fire_space_time = reshape(forecast_vectors_ML_model_median_this_scen,length(good_fuel_lin_inds),length(datetime_forecast_hours));

    for hours_i = 1:length(datetime_forecast_hours)

        space_vector_this_hour = squeeze(forecast_FRP_given_fire_space_time(:,hours_i));

        empty_map_this_hour = NaN(size(wrf_lat_2d,1),size(wrf_lat_2d,2));

        empty_map_this_hour(good_fuel_lin_inds) = space_vector_this_hour;

        forecast_FRP_given_fire(:,:,hours_i,all_scenario_i) = empty_map_this_hour;

    end
end

%% pre-allocate for weather components

weather_affected_components_names = ["Wind (m/s)",...
                                     "Temperature (K)",...
                                     "Relative Humidity (%)",...
                                     "Precipitation (mm/hr)",...
                                     "1-hr DFM (%)",...
                                     "10-hr DFM (%)",...
                                     "100-hr DFM (%)",...
                                     "1000-hr DFM (%)"];

weather_affected_components_lin = NaN(length(good_fuel_lin_inds),num_hours_forecast,length(climate_scenario_names),length(weather_affected_components_names));

weather_affected_components_lin(:,:,1,1) = wind_array;
weather_affected_components_lin(:,:,2,1) = wind_array;
weather_affected_components_lin(:,:,3,1) = wind_array;
weather_affected_components_lin(:,:,:,2) = temperature_array;
weather_affected_components_lin(:,:,:,3) = RH_array;
weather_affected_components_lin(:,:,1,4) = precip_array;
weather_affected_components_lin(:,:,2,4) = precip_array;
weather_affected_components_lin(:,:,3,4) = precip_array;
weather_affected_components_lin(:,:,:,5) = DFM_array_1_hr;
weather_affected_components_lin(:,:,:,6) = DFM_array_10_hr;
weather_affected_components_lin(:,:,:,7) = DFM_array_100_hr;
weather_affected_components_lin(:,:,:,8) = DFM_array_1000_hr;

weather_affected_components = NaN(size(wrf_lat_2d,1),size(wrf_lat_2d,2),num_hours_forecast,length(climate_scenario_names),length(weather_affected_components_names));

for temp_scenarios_i = 1:length(climate_scenario_names)

    for weather_comps_i = 1:length(weather_affected_components_names)

        linear_array_this_scen = squeeze(weather_affected_components_lin(:,:,temp_scenarios_i,weather_comps_i));

        for hours_i = 1:length(datetime_forecast_hours)
    
            space_vector_this_hour = squeeze(linear_array_this_scen(:,hours_i));
            empty_map_this_hour = NaN(size(wrf_lat_2d,1),size(wrf_lat_2d,2));
            empty_map_this_hour(good_fuel_lin_inds) = space_vector_this_hour;
            weather_affected_components(:,:,hours_i,temp_scenarios_i,weather_comps_i) = empty_map_this_hour;

        end
    end
end

%% calc the change from today

forecast_FRP_given_fire_change = NaN(size(forecast_FRP_given_fire));

for all_scenario_i = 1:length(all_scenario_names)

    forecast_FRP_given_fire_change(:,:,:,all_scenario_i) = forecast_FRP_given_fire(:,:,:,all_scenario_i) - forecast_FRP_given_fire(:,:,:,1);

end

%% make daily mean arrays but only for days with 24 full hours in Pacific Time

Pacific_UTC_offset = 8;

datetime_forecast_hours_PT = datetime_forecast_hours-hours(Pacific_UTC_offset);
datetime_forecast_hours_days_PT = day(datetime_forecast_hours_PT);

day_dates_PT = unique(datetime_forecast_hours_days_PT,'stable');

day_dates_with_24_hours_PT = [];

for day_dates_i = 1:length(day_dates_PT)

    good_day_inds = find(datetime_forecast_hours_days_PT == day_dates_PT(day_dates_i));

    if length(good_day_inds) == 24

        day_dates_with_24_hours_PT = horzcat(day_dates_with_24_hours_PT,day_dates_PT(day_dates_i));

    end
end

forecast_FRP_given_fire_day = NaN(size(wrf_lat_2d,1),size(wrf_lat_2d,2),length(day_dates_with_24_hours_PT),length(all_scenario_names));
weather_affected_components_day = NaN(size(wrf_lat_2d,1),size(wrf_lat_2d,2),length(day_dates_with_24_hours_PT),length(climate_scenario_names),length(weather_affected_components_names));

for day_dates_with_24h_i = 1:length(day_dates_with_24_hours_PT)

    good_day_inds = find(datetime_forecast_hours_days_PT == day_dates_with_24_hours_PT(day_dates_with_24h_i));

    forecast_FRP_given_fire_day(:,:,day_dates_with_24h_i,:) = mean(forecast_FRP_given_fire(:,:,good_day_inds,:),3);

    weather_affected_components_day(:,:,day_dates_with_24h_i,:,:) = mean(weather_affected_components(:,:,good_day_inds,:,:),3);

end

first_good_day_i_datetime = find(datetime_forecast_hours_days_PT == day_dates_with_24_hours_PT(1));
first_good_day_i_datetime = first_good_day_i_datetime(1);

last_good_day_i_datetime = find(datetime_forecast_hours_days_PT == day_dates_with_24_hours_PT(end));
last_good_day_i_datetime = last_good_day_i_datetime(1);

t1 = datetime(year(datetime_forecast_hours_PT(first_good_day_i_datetime)),month(datetime_forecast_hours_PT(first_good_day_i_datetime)),day(datetime_forecast_hours_PT(first_good_day_i_datetime)));
t2 = datetime(year(datetime_forecast_hours_PT(last_good_day_i_datetime)),month(datetime_forecast_hours_PT(last_good_day_i_datetime)),day(datetime_forecast_hours_PT(last_good_day_i_datetime)));
datetime_daily_values = t1:t2;

datetime_daily_names = datestr(datetime_daily_values);

%% calc the change from CC daily

CC_fractional_enhancement_day = forecast_FRP_given_fire_day(:,:,:,5)./forecast_FRP_given_fire_day(:,:,:,1);
CC_mean_enhancement_day = mean(CC_fractional_enhancement_day(:),"omitnan");

forecast_FRP_given_fire_change_day = NaN(size(forecast_FRP_given_fire_day));

for all_scenario_i = 1:length(all_scenario_names)

    forecast_FRP_given_fire_change_day(:,:,:,all_scenario_i) = forecast_FRP_given_fire_day(:,:,:,all_scenario_i) - forecast_FRP_given_fire_day(:,:,:,1);

end

%% write netcdfs - hourly

    time_values = 1:length(datetime_forecast_hours);
    
for output_file_i = 1:2

    % Define the filename
    if output_file_i == 1; filename = strcat(filename_base_path,'/calculate_FRP_forecast_for_different_scens.nc'); end
    if output_file_i == 2; filename = strcat(filename_base_path,'/calculate_FRP_forecast_for_different_scens_change.nc'); end

    % Mode for file creation (CLOBBER mode will overwrite existing files)
    mode = netcdf.getConstant('CLOBBER');
    
    % Create the file
    ncid = netcdf.create(filename, mode);
    
    % Define the dimensions
    lon_dim = netcdf.defDim(ncid, 'longitude', size(forecast_FRP_given_fire, 1));
    lat_dim = netcdf.defDim(ncid, 'latitude', size(forecast_FRP_given_fire, 2));
    time_dim = netcdf.defDim(ncid, 'time', size(forecast_FRP_given_fire, 3));
    var_dim = netcdf.defDim(ncid, 'variables', numel(all_scenario_names));
    
    % Find the maximum length of string in the array climate_scenario_names
    max_str_length = max(cellfun('length',all_scenario_names));
    
    % Define new dimension for the maximum string length
    str_dim = netcdf.defDim(ncid, 'str_dim', max_str_length);
    
    % Define the variables
    if output_file_i == 1; varid = netcdf.defVar(ncid, 'forecast_FRP_given_fire', 'double', [lon_dim lat_dim time_dim var_dim]); end
    if output_file_i == 2; varid = netcdf.defVar(ncid, 'forecast_FRP_given_fire_change', 'double', [lon_dim lat_dim time_dim var_dim]); end
    
    % Define 2D variables for longitude and latitude
    lon_varid = netcdf.defVar(ncid, 'longitude', 'double', [lon_dim lat_dim]);
    lat_varid = netcdf.defVar(ncid, 'latitude', 'double', [lon_dim lat_dim]);
    
    % Define other variables as before
    time_varid = netcdf.defVar(ncid, 'time', 'double', time_dim);
    
    % Define a single 2D variable to hold all the strings
    var_varid = netcdf.defVar(ncid, 'variable_names', 'char', [str_dim var_dim]);
    
    % End define mode
    netcdf.endDef(ncid);
    
    % Write the data to the variables
    if output_file_i == 1; netcdf.putVar(ncid, varid, forecast_FRP_given_fire); end
    if output_file_i == 2; netcdf.putVar(ncid, varid, forecast_FRP_given_fire_change); end

    netcdf.putVar(ncid, lon_varid, wrf_lon_2d);
    netcdf.putVar(ncid, lat_varid, wrf_lat_2d);
    netcdf.putVar(ncid, time_varid, time_values);
    
    % Create a 2D char array to hold all the strings
    str_array = char(all_scenario_names);
    
    % Write the 2D char array to the variable
    netcdf.putVar(ncid, var_varid, str_array);
    
    % Close the file
    netcdf.close(ncid);

end

%% write netcdfs - daily

%this doesnt write the day dates at the moment

    time_labels = datetime_daily_names;
    
for output_file_i = 1:2

    % Define the filename
    if output_file_i == 1; filename = strcat(filename_base_path,'/calculate_FRP_forecast_for_different_scens_daily.nc'); end
    if output_file_i == 2; filename = strcat(filename_base_path,'/calculate_FRP_forecast_for_different_scens_change_daily.nc'); end

    % Mode for file creation (CLOBBER mode will overwrite existing files)
    mode = netcdf.getConstant('CLOBBER');
    
    % Create the file
    ncid = netcdf.create(filename, mode);
    
    % Define the dimensions
    lon_dim = netcdf.defDim(ncid, 'longitude', size(forecast_FRP_given_fire_day, 1));
    lat_dim = netcdf.defDim(ncid, 'latitude', size(forecast_FRP_given_fire_day, 2));
    
    time_dim = netcdf.defDim(ncid, 'time', size(forecast_FRP_given_fire_day, 3));
    var_dim = netcdf.defDim(ncid, 'variables', numel(all_scenario_names));
    
    % Find the maximum length of string in the array climate_scenario_names
    max_str_length_var = max(cellfun('length',all_scenario_names));
    max_str_length_time = length(time_labels);
    
    % Define new dimension for the maximum string length
    str_dim_var = netcdf.defDim(ncid, 'str_dim_var', max_str_length_var);
    str_dim_time = netcdf.defDim(ncid, 'str_dim_time', max_str_length_time);
    
    % Define the variables
    if output_file_i == 1; varid = netcdf.defVar(ncid, 'forecast_FRP_given_fire', 'double', [lon_dim lat_dim time_dim var_dim]); end
    if output_file_i == 2; varid = netcdf.defVar(ncid, 'forecast_FRP_given_fire_change', 'double', [lon_dim lat_dim time_dim var_dim]); end
    
    % Define 2D variables for longitude and latitude
    lon_varid = netcdf.defVar(ncid, 'longitude', 'double', [lon_dim lat_dim]);
    lat_varid = netcdf.defVar(ncid, 'latitude', 'double', [lon_dim lat_dim]);
    
    % Define other variables as before
    
    % Define a single 2D variable to hold all the strings
    var_varid = netcdf.defVar(ncid, 'variable_names', 'char', [var_dim str_dim_var]);
    time_varid = netcdf.defVar(ncid, 'day_names', 'char', [time_dim str_dim_time]);
    
    % End define mode
    netcdf.endDef(ncid);
    
    % Write the data to the variables
    if output_file_i == 1; netcdf.putVar(ncid, varid, forecast_FRP_given_fire_day); end
    if output_file_i == 2; netcdf.putVar(ncid, varid, forecast_FRP_given_fire_change_day); end

    netcdf.putVar(ncid, lon_varid, wrf_lon_2d);
    netcdf.putVar(ncid, lat_varid, wrf_lat_2d);
    
    % Create a 2D char array to hold all the strings
    str_array_var = char(all_scenario_names);
    str_array_time = time_labels;
    
    % Write the 2D char array to the variable
    netcdf.putVar(ncid, var_varid, str_array_var);
    netcdf.putVar(ncid, time_varid, str_array_time);
    
    % Close the file
    netcdf.close(ncid);

end

%% write hourly constituents netcdfs

%weather_affected_components = NaN(size(wrf_lat_2d,1),size(wrf_lat_2d,2),num_hours_forecast,length(climate_scenario_names),length(weather_affected_components_names));

    time_values = 1:length(datetime_forecast_hours);

for clim_scens_i = 1:length(climate_scenario_names)

    weather_affected_components_this_clim = squeeze(weather_affected_components(:,:,:,clim_scens_i,:));

    % Define the filename

    if clim_scens_i == 1; filename = strcat(filename_base_path,'/weather_varying_components_current_clim.nc'); end
    if clim_scens_i == 2; filename = strcat(filename_base_path,'/weather_varying_components_2050_RCP26.nc'); end
    if clim_scens_i == 3; filename = strcat(filename_base_path,'/weather_varying_components_2050_RCP45.nc'); end

    % Mode for file creation (CLOBBER mode will overwrite existing files)
    mode = netcdf.getConstant('CLOBBER');
    
    % Create the file
    ncid = netcdf.create(filename, mode);
    
    % Define the dimensions
    lon_dim = netcdf.defDim(ncid, 'longitude', size(weather_affected_components_this_clim, 1));
    lat_dim = netcdf.defDim(ncid, 'latitude', size(weather_affected_components_this_clim, 2));
    time_dim = netcdf.defDim(ncid, 'time', size(weather_affected_components_this_clim, 3));
    var_dim = netcdf.defDim(ncid, 'variables', numel(weather_affected_components_names));
    
    % Find the maximum length of string in the array climate_scenario_names
    max_str_length = max(cellfun('length',weather_affected_components_names));
    
    % Define new dimension for the maximum string length
    str_dim = netcdf.defDim(ncid, 'str_dim', max_str_length);
    
    % Define the variables
    varid = netcdf.defVar(ncid, 'weather_affected_components_this_clim', 'double', [lon_dim lat_dim time_dim var_dim]);
    
    % Define 2D variables for longitude and latitude
    lon_varid = netcdf.defVar(ncid, 'longitude', 'double', [lon_dim lat_dim]);
    lat_varid = netcdf.defVar(ncid, 'latitude', 'double', [lon_dim lat_dim]);
    
    % Define other variables as before
    time_varid = netcdf.defVar(ncid, 'time', 'double', time_dim);
    
    % Define a single 2D variable to hold all the strings
    var_varid = netcdf.defVar(ncid, 'variable_names', 'char', [str_dim var_dim]);
    
    % End define mode
    netcdf.endDef(ncid);
    
    % Write the data to the variables
    netcdf.putVar(ncid, varid, weather_affected_components_this_clim);

    netcdf.putVar(ncid, lon_varid, wrf_lon_2d);
    netcdf.putVar(ncid, lat_varid, wrf_lat_2d);
    netcdf.putVar(ncid, time_varid, time_values);
    
    % Create a 2D char array to hold all the strings
    str_array = char(weather_affected_components_names);
    
    % Write the 2D char array to the variable
    netcdf.putVar(ncid, var_varid, str_array);
    
    % Close the file
    netcdf.close(ncid);

end


%% find the highest concern areas to put on map (for daily)

acres_per_2km_by_2km_grid_box = 988.42;
acres_of_high_priority_to_ID = 1000000;

num_grid_boxes_of_high_concern = round(acres_of_high_priority_to_ID./acres_per_2km_by_2km_grid_box,0);

highest_concern_lats_daily = NaN(num_grid_boxes_of_high_concern,length(day_dates_with_24_hours_PT),length(all_scenario_names));
highest_concern_lons_daily = NaN(num_grid_boxes_of_high_concern,length(day_dates_with_24_hours_PT),length(all_scenario_names));

lin_lats = wrf_lat_2d(:);
lin_lons = wrf_lon_2d(:);

for day_dates_with_24h_i = 1:length(day_dates_with_24_hours_PT)  % Assuming the 3rd dimension is time
    for all_scenario_i = 1:length(all_scenario_names)

        map_now = squeeze(forecast_FRP_given_fire_day(:,:,day_dates_with_24h_i,all_scenario_i));
        map_now(isnan(map_now)) = 0;

        [B,I] = sort(map_now(:),'descend');

        highest_concern_lats_daily(:,day_dates_with_24h_i,all_scenario_i) = lin_lats(I(1:num_grid_boxes_of_high_concern));
        highest_concern_lons_daily(:,day_dates_with_24h_i,all_scenario_i) = lin_lons(I(1:num_grid_boxes_of_high_concern));

    end
end

%% find the highest concern areas to put on map (for hourly)

highest_conern_lats_hourly = NaN(num_grid_boxes_of_high_concern,num_hours_forecast,length(all_scenario_names));
highest_concern_lons_hourly = NaN(num_grid_boxes_of_high_concern,num_hours_forecast,length(all_scenario_names));

for hours_i = 1:length(datetime_forecast_hours)
    for all_scenario_i = 1:length(all_scenario_names)

        map_now = squeeze(forecast_FRP_given_fire(:,:,hours_i,all_scenario_i));
        map_now(isnan(map_now)) = 0;

        [B,I] = sort(map_now(:),'descend');

        highest_conern_lats_hourly(:,hours_i,all_scenario_i) = lin_lats(I(1:num_grid_boxes_of_high_concern));
        highest_concern_lons_hourly(:,hours_i,all_scenario_i) = lin_lons(I(1:num_grid_boxes_of_high_concern));

    end
end

%% save 

 save(strcat(filename_base_path,'/highest_concern_lat_lons.mat'),...
     'highest_concern_lats_daily',...
     'highest_concern_lons_daily',...
     'highest_conern_lats_hourly',...
     'highest_concern_lons_hourly')

