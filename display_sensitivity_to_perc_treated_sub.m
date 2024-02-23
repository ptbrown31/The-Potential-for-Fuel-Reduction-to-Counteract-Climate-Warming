close all 
clear all

base_path = '';

%% load

read_in_FRP_top_hours_inds = 1:30;

hour_to_assess_i = 1;

    load(strcat(base_path,'calc_FPIs_for_multiple_hours_palced_in_diff_scens_hour_',num2str(read_in_FRP_top_hours_inds(hour_to_assess_i)),'.mat'),...
    'all_predictor_variables_var_names_used',...
    'all_scenario_names',...
    'wrf_lat_2d',...
    'wrf_lon_2d')

FIP_maps_all_days = NaN(size(wrf_lon_2d,1),size(wrf_lat_2d,2),length(all_scenario_names),length(read_in_FRP_top_hours_inds));
FIP_maps_all_days_lin = NaN(numel(wrf_lat_2d),length(all_scenario_names),length(read_in_FRP_top_hours_inds));

rand = 0;

for hour_to_assess_i = 1:length(read_in_FRP_top_hours_inds)
       
    if rand == 0

        load(strcat(base_path,'calc_FPIs_for_multiple_hours_palced_in_diff_scens_hour_',num2str(read_in_FRP_top_hours_inds(hour_to_assess_i)),'.mat'),...
        'forecast_FRP_given_fire')

    end

    if rand == 1

        load(strcat(base_path,'calc_FPIs_for_multiple_hours_palced_in_diff_scens_hour_rand_',num2str(read_in_FRP_top_hours_inds(hour_to_assess_i)),'.mat'),...
        'forecast_FRP_given_fire')

    end

        FIP_maps_all_days(:,:,:,hour_to_assess_i) = forecast_FRP_given_fire;

        for scen_i = 1:length(all_scenario_names)

            map_now = forecast_FRP_given_fire(:,:,scen_i);

            FIP_maps_all_days_lin(:,scen_i,hour_to_assess_i) = map_now(:);

        end
end

%% find pixels to target

FIP_maps = mean(FIP_maps_all_days,4);

FIP_map_effect_of_treatment_today = FIP_maps(:,:,1) - FIP_maps(:,:,2);

FIP_map_effect_of_treatment_today_lin = FIP_map_effect_of_treatment_today(:);

[B_lin I_lin] = sort(FIP_map_effect_of_treatment_today_lin,"ascend");

%% how much total area is there?

acres_per_2km_by_2km_grid_box = 988.42;

non_nan_pixels = sum(~isnan(FIP_map_effect_of_treatment_today_lin));

non_nan_area = non_nan_pixels.*acres_per_2km_by_2km_grid_box;

%% Define treatment areas

fuel_treatment_area_labes = ["0 million" "1 million" "2 million" "4 million" "8 million" "48 million"];

fuel_treatment_areas = [0 1 2 4 8 48].*1E6;

fuel_treatment_num_grid_boxes = round(fuel_treatment_areas./acres_per_2km_by_2km_grid_box,0);

%% assemble

climate_labes = ["Today" "2050" "2090"];
emissions_labes = ["SSP1-2.6" "SSP2-4.5"];

FIP_all_maps_lin = NaN(numel(wrf_lon_2d),...
                       length(read_in_FRP_top_hours_inds),...
                       length(climate_labes),...
                       length(emissions_labes),...
                       length(fuel_treatment_area_labes));

        FIP_all_maps_lin(:,:,1,1,1) = FIP_maps_all_days_lin(:,2,:);
        FIP_all_maps_lin(:,:,2,1,1) = FIP_maps_all_days_lin(:,4,:);
        FIP_all_maps_lin(:,:,3,1,1) = FIP_maps_all_days_lin(:,8,:);
    
        FIP_all_maps_lin(:,:,1,2,1) = FIP_maps_all_days_lin(:,2,:);
        FIP_all_maps_lin(:,:,2,2,1) = FIP_maps_all_days_lin(:,6,:);
        FIP_all_maps_lin(:,:,3,2,1) = FIP_maps_all_days_lin(:,10,:);

for fuel_treat_areas_i = 2:length(fuel_treatment_area_labes)

        FIP_all_maps_lin(:,:,1,1,fuel_treat_areas_i) = FIP_maps_all_days_lin(:,2,:);
        FIP_all_maps_lin(:,:,2,1,fuel_treat_areas_i) = FIP_maps_all_days_lin(:,4,:);
        FIP_all_maps_lin(:,:,3,1,fuel_treat_areas_i) = FIP_maps_all_days_lin(:,8,:);
    
        FIP_all_maps_lin(:,:,1,2,fuel_treat_areas_i) = FIP_maps_all_days_lin(:,2,:);
        FIP_all_maps_lin(:,:,2,2,fuel_treat_areas_i) = FIP_maps_all_days_lin(:,6,:);
        FIP_all_maps_lin(:,:,3,2,fuel_treat_areas_i) = FIP_maps_all_days_lin(:,10,:);

        inds_of_pixels_to_swap = I_lin(1:fuel_treatment_num_grid_boxes(fuel_treat_areas_i));
    
        FIP_all_maps_lin(inds_of_pixels_to_swap,:,1,1,fuel_treat_areas_i) = FIP_maps_all_days_lin(inds_of_pixels_to_swap,1,:);
        FIP_all_maps_lin(inds_of_pixels_to_swap,:,2,1,fuel_treat_areas_i) = FIP_maps_all_days_lin(inds_of_pixels_to_swap,3,:);
        FIP_all_maps_lin(inds_of_pixels_to_swap,:,3,1,fuel_treat_areas_i) = FIP_maps_all_days_lin(inds_of_pixels_to_swap,7,:);
    
        FIP_all_maps_lin(inds_of_pixels_to_swap,:,1,2,fuel_treat_areas_i) = FIP_maps_all_days_lin(inds_of_pixels_to_swap,1,:);
        FIP_all_maps_lin(inds_of_pixels_to_swap,:,2,2,fuel_treat_areas_i) = FIP_maps_all_days_lin(inds_of_pixels_to_swap,5,:);
        FIP_all_maps_lin(inds_of_pixels_to_swap,:,3,2,fuel_treat_areas_i) = FIP_maps_all_days_lin(inds_of_pixels_to_swap,9,:);
end

%% turn maps into 2D

FIP_all_maps_2d = NaN(size(wrf_lat_2d,1),...
                      size(wrf_lat_2d,2),...
                      length(read_in_FRP_top_hours_inds),...
                      length(climate_labes),...
                      length(emissions_labes),...
                      length(fuel_treatment_area_labes));

for hour_to_assess_i = 1:length(read_in_FRP_top_hours_inds)
    for climate_i = 1:length(climate_labes)
        for emissions_i = 1:length(emissions_labes)
            for treat_perc_i = 1:length(fuel_treatment_area_labes)

                lin_map_now = squeeze(FIP_all_maps_lin(:,hour_to_assess_i,climate_i,emissions_i,treat_perc_i));

                FIP_all_maps_2d(:,:,hour_to_assess_i,climate_i,emissions_i,treat_perc_i) = reshape(lin_map_now,size(wrf_lat_2d));

            end
        end
    end
end

%% make means across days

FIP_day_mean_maps_2d = squeeze(mean(FIP_all_maps_2d,3));

%% make difference from means

FIP_day_mean_maps_2d_change = NaN(size(FIP_day_mean_maps_2d));

for climate_i = 1:length(climate_labes)
    for emissions_i = 1:length(emissions_labes)
        for treat_perc_i = 1:length(fuel_treatment_area_labes)

            lin_map_now = squeeze(FIP_all_maps_lin(:,hour_to_assess_i,climate_i,emissions_i,treat_perc_i));

            FIP_day_mean_maps_2d_change(:,:,climate_i,emissions_i,treat_perc_i) = FIP_day_mean_maps_2d(:,:,climate_i,emissions_i,treat_perc_i) - FIP_day_mean_maps_2d(:,:,1,1,1);

        end
    end
end


%% plot maps

emissions_i = 2;

FigHandle = figure('Position', [100, 100, 250, 1000]); %[left bottom width height]
set(gcf,'color',[1 1 1]);
set(0, 'DefaultAxesFontSize',9);
set(0,'defaultAxesFontName', 'helvetica');

subplotRows = 6;
subplotCols = 2;
padding = 0.03;
subplotWidth = (1 - (subplotCols + 1) * padding) / subplotCols;
subplotHeight = (1 - (subplotRows + 1) * padding) / subplotRows;

lin_plot_count = 1;

for treat_perc_i = 1:length(fuel_treatment_area_labes)
       for climate_i = 2:length(climate_labes) 
            left = padding + (mod(lin_plot_count - 1, subplotCols)) * (subplotWidth + padding);
            bottom = 1 - (ceil(lin_plot_count / subplotCols)) * (subplotHeight + padding);
            subplot('Position', [left bottom subplotWidth subplotHeight]);
            hold on;
        
            axesm('robinson',...
                  'Frame', 'off',...
                  'Grid', 'off',...
                  'maplatlim',[min(min(wrf_lat_2d)) max(max(wrf_lat_2d))-0.3],...
                  'maplonlim',[min(min(wrf_lon_2d))+1.4 max(max(wrf_lon_2d))-0.4])
            tightmap;
        
            map_now = squeeze(FIP_day_mean_maps_2d_change(:,:,climate_i,emissions_i,treat_perc_i));
            pcolorm(wrf_lat_2d, wrf_lon_2d, map_now, 'LineStyle', 'none');
            clim([-1000 1000]);

            map_now_mean = mean(map_now(:),"omitnan");
        
            lin_plot_count = lin_plot_count + 1;
       end
end

colormap('redblue')

%% make spatial means

FIP_all_map_means = squeeze(mean(FIP_all_maps_lin,1,"omitnan"));

%% Average

FIP_all_map_means_day_means = squeeze(mean(FIP_all_map_means,1));
FIP_all_map_means_day_STDs = squeeze(std(FIP_all_map_means,1));

FIP_all_map_means_day_STDERRs = FIP_all_map_means_day_STDs./sqrt(length(read_in_FRP_top_hours_inds));
FIP_all_map_means_day_STDERRs_half = FIP_all_map_means_day_STDERRs./2;

%% fractional changes

baseline_value = FIP_all_map_means_day_means(1,1,1);

frac_change = FIP_all_map_means_day_means./baseline_value;

%% plot

x_for_lines = [2022 2048 2088; ...
               2023 2049 2089; ...
               2024 2050 2090; ...
               2025 2051 2091; ...
               2026 2052 2092; ...
               2027 2053 2092];

x_for_lines = x_for_lines-0.5;

xlim_min = 2010;
xlim_max = 2100;

if rand == 0
    ylim_min = 290;
    ylim_max = 750;
end

if rand == 1
    ylim_min = 150;
    ylim_max = 375;
end

plot_colors = ["r" "m" "k" "g" "c" "b"];

    FigHandle = figure('Position', [100, 100, 1400, 600]); %[left bottom width height]
    set(gcf,'color',[1 1 1]);
    set(0, 'DefaultAxesFontSize',14);
    set(0,'defaultAxesFontName', 'helvetica')
    
    for emissions_i = 1:length(emissions_labes)

        subplot(1,2,emissions_i)
        hold on
    
        for treat_perc_i = 1:length(fuel_treatment_area_labes)
    
            plot(x_for_lines(treat_perc_i,:),[squeeze(FIP_all_map_means_day_means(1,1,1)) squeeze(FIP_all_map_means_day_means(2:end,emissions_i,treat_perc_i))'],strcat('-',plot_colors(treat_perc_i)),'LineWidth',2)
            scatter(x_for_lines(treat_perc_i,:),FIP_all_map_means_day_means(:,emissions_i,treat_perc_i),100,plot_colors(treat_perc_i),"filled","o","MarkerEdgeColor","none","MarkerFaceAlpha",0.9)

            for climate_i = 1:length(climate_labes)

                if climate_i == 1; x_offset = -7; end
                if climate_i == 2; x_offset = -7; end
                if climate_i == 3; x_offset = 3; end

                plot([x_for_lines(treat_perc_i,climate_i) x_for_lines(treat_perc_i,climate_i)],[FIP_all_map_means_day_means(climate_i,emissions_i,treat_perc_i)-FIP_all_map_means_day_STDERRs_half(climate_i,emissions_i,treat_perc_i) FIP_all_map_means_day_means(climate_i,emissions_i,treat_perc_i)+FIP_all_map_means_day_STDERRs_half(climate_i,emissions_i,treat_perc_i)],strcat('-',plot_colors(treat_perc_i)),'LineWidth',4)
                text(x_for_lines(treat_perc_i,climate_i)+x_offset,FIP_all_map_means_day_means(climate_i,emissions_i,treat_perc_i)+0,strcat(num2str(round(100.*frac_change(climate_i,emissions_i,treat_perc_i),0)),'%'))
            end
    
        end

        plot([x_for_lines(1) x_for_lines(end)],[FIP_all_map_means_day_means(1,1,1) FIP_all_map_means_day_means(1,1,1)],'-k','LineWidth',2)
    
        xlim([xlim_min xlim_max])
        ylim([ylim_min ylim_max])

        ylabel("Average Fire Intensity Potential (MW)")
        xlabel("Year")

        title(emissions_labes(emissions_i))

    end

%% main text figure

fuel_treatment_areas_inds_to_plot = [1 5 6];

x_for_lines_1 = [2024 2049 2089];
x_for_lines_2 = [2024 2051 2091];

x_offsets_1 = [-7 -7 2];
x_offsets_2 = [-7 1.5 2];

y_offsets_26 = [0 -7 0];

if rand == 1; y_offsets_45 = [0 9 0]; end
if rand == 0; y_offsets_45 = [0 16 0]; end

    FigHandle = figure('Position', [100, 100, 600, 600]); %[left bottom width height]
    set(gcf,'color',[1 1 1]);
    set(0, 'DefaultAxesFontSize',17);
    set(0,'defaultAxesFontName', 'helvetica')

    hold on
  
    for emissions_i = 1:length(emissions_labes)
        for treat_perc_i = 1:length(fuel_treatment_areas_inds_to_plot)
            for climate_i = 1:length(climate_labes)

            if emissions_i == 1; x_for_lines = x_for_lines_1; x_offsets = x_offsets_1; y_offset = y_offsets_26; end
            if emissions_i == 2; x_for_lines = x_for_lines_2; x_offsets = x_offsets_2; y_offset = y_offsets_45; end

            if treat_perc_i == 1 && emissions_i == 1; plot_color = [0.8500 0.3250 0.0980]; y_offset = y_offsets_45; end
            if treat_perc_i == 1 && emissions_i == 2; plot_color = [0.6350 0.0780 0.1840]; end

            if treat_perc_i == 2 && emissions_i == 1; plot_color = [0.4660 0.6740 0.1880]; end
            if treat_perc_i == 2 && emissions_i == 2; plot_color = [0.4940 0.1840 0.5560]; end

            if treat_perc_i == 3 && emissions_i == 1; plot_color = [0 0.4470 0.7410]; end
            if treat_perc_i == 3 && emissions_i == 2; plot_color = [0.3010 0.7450 0.9330]; end

                plot(x_for_lines,[squeeze(FIP_all_map_means_day_means(1,1,1)) squeeze(FIP_all_map_means_day_means(2:end,emissions_i,fuel_treatment_areas_inds_to_plot(treat_perc_i)))'],"Color",plot_color,'LineWidth',3)
                scatter(x_for_lines,FIP_all_map_means_day_means(:,emissions_i,fuel_treatment_areas_inds_to_plot(treat_perc_i)),100,"filled","o","MarkerEdgeColor","none","MarkerFaceColor",plot_color,"MarkerFaceAlpha",0.9)

                plot([x_for_lines(climate_i) x_for_lines(climate_i)],[FIP_all_map_means_day_means(climate_i,emissions_i,fuel_treatment_areas_inds_to_plot(treat_perc_i))-FIP_all_map_means_day_STDERRs_half(climate_i,emissions_i,fuel_treatment_areas_inds_to_plot(treat_perc_i)) FIP_all_map_means_day_means(climate_i,emissions_i,fuel_treatment_areas_inds_to_plot(treat_perc_i))+FIP_all_map_means_day_STDERRs_half(climate_i,emissions_i,fuel_treatment_areas_inds_to_plot(treat_perc_i))],"Color",plot_color,'LineWidth',4)
                
                text(x_for_lines(climate_i)+x_offsets(climate_i),FIP_all_map_means_day_means(climate_i,emissions_i,fuel_treatment_areas_inds_to_plot(treat_perc_i))+y_offset(climate_i),strcat(num2str(round(100.*frac_change(climate_i,emissions_i,fuel_treatment_areas_inds_to_plot(treat_perc_i)),0)),'%'),"FontSize",12)
            end
        end

        plot([x_for_lines(1) x_for_lines(end)],[FIP_all_map_means_day_means(1,1,1) FIP_all_map_means_day_means(1,1,1)],'-k','LineWidth',2)
    
        xlim([xlim_min xlim_max])
        ylim([ylim_min ylim_max])

        ylabel("Average Fire Intensity Potential (MW)")
        xlabel("Year")

    end