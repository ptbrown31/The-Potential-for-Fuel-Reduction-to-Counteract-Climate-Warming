close all 
clear all

base_path = '';

%% load

load(strcat(base_path,'read_landfire_2022_fuel_for_viirs_all_detect.mat'),...
    'all_land_var_names',...
    'all_land_vars_wrf_grid_map')

load(strcat(base_path,'choose_times_for_case_study_hour_series.mat'),...
    'lats_of_fires_by_hour',...
    'lons_of_fires_by_hour',...
    'FRPs_of_fires_by_hour')

load(strcat(base_path,'choose_times_for_case_study.mat'),...
    'viirs_all_detect_table',...
    'viirs_range_hourly_datetime_array',...
    'total_domain_FRP_each_hour',...
    'hours_ranked_by_FRP',...
    'FRP_ranked_by_FRP',...
    'top_FRP_hours',...
    'top_FRPs',...
    'ranked_FRP_hours_inds',...
    'random_hour_inds',...
    'top_FRP_hours_seperated',...
    'top_FRPs_seperated',...
    'random_FRP_hours_seperated',...
    'random_FRPs_seperated')

read_in_FRP_top_hours_inds = 1:30;

hour_to_assess_i = 1;

    load(strcat(base_path,'calc_FPIs_for_multiple_hours_palced_in_diff_scens_hour_',num2str(read_in_FRP_top_hours_inds(hour_to_assess_i),'.mat')),...
    'all_predictor_variables_var_names_used',...
    'all_scenario_names',...
    'wrf_lat_2d',...
    'wrf_lon_2d')

predictor_maps_all_days = NaN(size(wrf_lon_2d,1),size(wrf_lat_2d,2),length(all_predictor_variables_var_names_used),length(all_scenario_names),length(read_in_FRP_top_hours_inds));
FIP_all_days = NaN(size(wrf_lon_2d,1),size(wrf_lat_2d,2),length(all_scenario_names),length(read_in_FRP_top_hours_inds));

for hour_to_assess_i = 1:length(read_in_FRP_top_hours_inds)

    load(strcat(base_path,'calc_FPIs_for_multiple_hours_palced_in_diff_scens_hour_',num2str(read_in_FRP_top_hours_inds(hour_to_assess_i),'.mat')),...
    'predictor_maps',...
    'forecast_FRP_given_fire')

    predictor_maps_all_days(:,:,:,:,hour_to_assess_i) = predictor_maps;
    FIP_all_days(:,:,:,hour_to_assess_i) = forecast_FRP_given_fire;

end

predictor_maps_all_days_mean = mean(predictor_maps_all_days,5);
FIP_all_days_mean = mean(FIP_all_days,4);

%% plot fuel scenario predictor changes

fuel_inds = 2:11;

c_maxes = [6 4 6 1 3.5 5 75 35 6 0.2];

all_predictor_variables_var_names_used_fuel = all_predictor_variables_var_names_used(fuel_inds);

fuel_maps_pre = predictor_maps_all_days_mean(:,:,fuel_inds,2);
fuel_maps_post = predictor_maps_all_days_mean(:,:,fuel_inds,1);

fuel_maps_pre_post = cat(4,fuel_maps_pre,fuel_maps_post);

plot_positions = [1 2 5 6 9 10 13 14 17 18 3 4 7 8 11 12 15 16 19 20];

subplotRows = 5;
subplotCols = 4;
padding = 0.01;
subplotWidth = (1 - (subplotCols + 1) * padding) / subplotCols;
subplotHeight = (1 - (subplotRows + 1) * padding) / subplotRows;

FigHandle = figure('Position', [100, 100, 600, 900]); %[left bottom width height]
set(gcf,'color',[1 1 1]);
set(0, 'DefaultAxesFontSize',9);
set(0,'defaultAxesFontName', 'helvetica')

lin_plot_ind = 1;

for pre_post_i = 1:2
    for fuel_i = 1:length(fuel_inds)

        left = padding + (mod(plot_positions(lin_plot_ind) - 1, subplotCols)) * (subplotWidth + padding);
        bottom = 1 - (ceil(plot_positions(lin_plot_ind) / subplotCols)) * (subplotHeight + padding);
        subplot('Position', [left bottom subplotWidth subplotHeight]);
        hold on;

        axesm('robinson',...
        'Frame', 'off',...
        'Grid', 'off',...
        'maplatlim',[min(min(wrf_lat_2d)) max(max(wrf_lat_2d))-0.3],...
        'maplonlim',[min(min(wrf_lon_2d))+1.4 max(max(wrf_lon_2d))-0.4])
        tightmap

        map_now = squeeze(fuel_maps_pre_post(:,:,fuel_i,pre_post_i));

        pcolorm(wrf_lat_2d,wrf_lon_2d,map_now,'LineStyle','none');

        map_mean = mean(map_now(:),"omitnan");

        textm(34.5,-124.3,strcat('Mean=',num2str(round(map_mean,2))),'FontSize',8)

        title(all_predictor_variables_var_names_used_fuel(fuel_i));

        t=colorbar;
        clim([0 c_maxes(fuel_i)])
        lin_plot_ind = lin_plot_ind + 1;

    end
end

%% plot climate change scenario changes

weather_inds = 12:16;
scen_inds = [2 6 10];

all_predictor_variables_var_names_used_weather = all_predictor_variables_var_names_used(weather_inds);
all_scenario_names_plot_weather = all_scenario_names(scen_inds);

weather_maps_to_plot = predictor_maps_all_days_mean(:,:,weather_inds,scen_inds);

c_maxes = zeros(1,15)+20;
c_maxes(end-2:end) = 8;

plot_positions = 1:15;

subplotRows = 5;
subplotCols = 3;
padding = 0.01;
subplotWidth = (1 - (subplotCols + 1) * padding) / subplotCols;
subplotHeight = (1 - (subplotRows + 1) * padding) / subplotRows;

FigHandle = figure('Position', [100, 100, 450, 900]); %[left bottom width height]
set(gcf,'color',[1 1 1]);
set(0, 'DefaultAxesFontSize',9);
set(0,'defaultAxesFontName', 'helvetica')

lin_plot_ind = 1;

for weather_var_i = 1:length(weather_inds)
    for scen_i = 1:length(scen_inds)

        left = padding + (mod(plot_positions(lin_plot_ind) - 1, subplotCols)) * (subplotWidth + padding);
        bottom = 1 - (ceil(plot_positions(lin_plot_ind) / subplotCols)) * (subplotHeight + padding);
        subplot('Position', [left bottom subplotWidth subplotHeight]);
        hold on;

        axesm('robinson',...
        'Frame', 'off',...
        'Grid', 'off',...
        'maplatlim',[min(min(wrf_lat_2d)) max(max(wrf_lat_2d))-0.3],...
        'maplonlim',[min(min(wrf_lon_2d))+1.4 max(max(wrf_lon_2d))-0.4])
        tightmap

        map_now = squeeze(weather_maps_to_plot(:,:,weather_var_i,scen_i));

        pcolorm(wrf_lat_2d,wrf_lon_2d,map_now,'LineStyle','none');

        map_mean = mean(map_now(:),"omitnan");

        textm(34.5,-124.3,strcat('Mean=',num2str(round(map_mean,2))),'FontSize',8)

        if weather_var_i <= 5

            cmap = colormap('parula');
            reversedCmap = flipud(cmap);
            colormap(reversedCmap);

        else

            cmap = colormap('parula');
            colormap(cmap);

        end
        
        clim([0 c_maxes(lin_plot_ind)])
        lin_plot_ind = lin_plot_ind + 1;

    end
end

%% calc change

FIP_all_days_mean_change = NaN(size(FIP_all_days_mean));

for scen_i = 1:length(all_scenario_names)

    FIP_all_days_mean_change(:,:,scen_i) = FIP_all_days_mean(:,:,scen_i) - FIP_all_days_mean(:,:,2);

end

%% calc some map means

    FIP_frac_change = NaN(length(all_scenario_names),length(read_in_FRP_top_hours_inds));
    FIP_map_means = NaN(length(all_scenario_names),length(read_in_FRP_top_hours_inds));
    
for hour_to_assess_i = 1:length(read_in_FRP_top_hours_inds)
    for all_scenario_i = 1:length(all_scenario_names)

        map = squeeze(FIP_all_days(:,:,all_scenario_i,hour_to_assess_i));

        FIP_map_means(all_scenario_i,hour_to_assess_i) = mean(map(:),"omitnan");

        map1 = squeeze(FIP_all_days(:,:,all_scenario_i,hour_to_assess_i));
        map2 = squeeze(FIP_all_days(:,:,2,hour_to_assess_i));
    
        FIP_frac_change(all_scenario_i,hour_to_assess_i) = mean(map1(:),"omitnan")./mean(map2(:),"omitnan");
    
    end
end

%% make 2 by 2 for composite raw

scens_to_plot = [4 6 3 5];

titles = ["No Fuel Reduction & RCP2.6",...
          "No Fuel Reduction & RCP4.5",...
          "Universal Fuel Reduction & RCP2.6",...
          "Universal Fuel Reduction & RCP4.5"];

    FigHandle = figure('Position', [100, 100, 600, 600]); %[left bottom width height]
    set(gcf,'color',[1 1 1]);
    set(0, 'DefaultAxesFontSize',9);
    set(0,'defaultAxesFontName', 'helvetica')

        for all_scenario_i = 1:length(scens_to_plot)

            subplot(2,2,all_scenario_i)
            hold on

                axesm('robinson',...
                'Frame', 'off',...
                'Grid', 'off',...
                'maplatlim',[min(min(wrf_lat_2d)) max(max(wrf_lat_2d))-0.3],...
                'maplonlim',[min(min(wrf_lon_2d))+1.4 max(max(wrf_lon_2d))-0.4])
                tightmap

                map_now = squeeze(FIP_all_days_mean(:,:,scens_to_plot(all_scenario_i)));

                pcolorm(wrf_lat_2d,wrf_lon_2d,map_now,'LineStyle','none');

                clim([0 2500])

                map_mean = mean(map_now(:),"omitnan");

            title(titles(all_scenario_i))
    
            textm(35,-125.6,strcat('Mean FIP =',num2str(round(mean(FIP_map_means(scens_to_plot(all_scenario_i),:),2,"omitnan"))),' MW, (',num2str(round(100.*mean(FIP_frac_change(scens_to_plot(all_scenario_i),:),2,"omitnan"))),'%)'),'FontSize',7)

        end

        sgtitle('Composite of 30 extreme hours placed in 2050 temperature')

        t=colorbar;
        t.Label.String = "Fire Intensity Potential (MW)";
        t.FontSize = 9;
        colormap('turbo')
        set(t, 'Position', [.902 .11 .0371 .81])

%% 2 by 3 raw (tight)

ref_map = squeeze(FIP_all_days_mean(:,:,2));
ref_map_mean = mean(ref_map(:),"omitnan");

scens_to_plot = [2 6 10 1 5 9];
titles = ["No Fuel Reduction, Today",...
          "No Fuel Reduction, 2050 RCP4.5",...
          "No Fuel Reduction, 2090 RCP4.5",...
          "Universal Fuel Reduction, Today",...
          "Universal Fuel Reduction, 2050 RCP4.5",...
          "Universal Fuel Reduction, 2090 RCP4.5"];

FigHandle = figure('Position', [100, 100, 600, 500]); %[left bottom width height]
set(gcf,'color',[1 1 1]);
set(0, 'DefaultAxesFontSize',9);
set(0,'defaultAxesFontName', 'helvetica');

subplotRows = 2;
subplotCols = 3;
padding = 0.03;
subplotWidth = (1 - (subplotCols + 1) * padding) / subplotCols;
subplotHeight = (1 - (subplotRows + 1) * padding) / subplotRows;

for all_scenario_i = 1:length(scens_to_plot)
    left = padding + (mod(all_scenario_i - 1, subplotCols)) * (subplotWidth + padding);
    bottom = 1 - (ceil(all_scenario_i / subplotCols)) * (subplotHeight + padding);
    subplot('Position', [left bottom subplotWidth subplotHeight]);
    hold on;

    axesm('robinson',...
          'Frame', 'off',...
          'Grid', 'off',...
          'maplatlim',[min(min(wrf_lat_2d)) max(max(wrf_lat_2d))-0.3],...
          'maplonlim',[min(min(wrf_lon_2d))+1.4 max(max(wrf_lon_2d))-0.4])
    tightmap;

    map_now = squeeze(FIP_all_days_mean(:,:,scens_to_plot(all_scenario_i)));
    pcolorm(wrf_lat_2d, wrf_lon_2d, map_now, 'LineStyle', 'none');
    clim([0 1500]);

    map_now_mean = mean(map_now(:),"omitnan");

    title(strcat('Mean FIP =', num2str(round(map_now_mean)), ' MW (', num2str(round(100.*map_now_mean./ref_map_mean)), '% of today)'), 'FontSize', 9);

end

colormap('turbo');

%% look at things by land type

range_borders_mins = [0.9 3.0 4.0];
range_borders_maxs = [3.0 4.0 5.0];

land_type_labels = ["Forest" "Shrub" "Grass"];
FIP_all_days_mean_by_land_type = NaN(size(wrf_lon_2d,1),size(wrf_lon_2d,2),length(all_scenario_names),length(land_type_labels));

for lon_i = 1:size(wrf_lon_2d,1)
    for lat_i = 1:size(wrf_lat_2d,2)
        for land_cat_i = 1:length(land_type_labels)
            if S_and_B_broad_cat(lon_i,lat_i) > range_borders_mins(land_cat_i) && S_and_B_broad_cat(lon_i,lat_i) <= range_borders_maxs(land_cat_i)

                FIP_all_days_mean_by_land_type(lon_i,lat_i,:,land_cat_i) = FIP_all_days_mean(lon_i,lat_i,:);

            end
        end
    end
end

%% plot FIP differnece by land type

FIP_all_days_mean_change_by_land = NaN(size(FIP_all_days_mean_by_land_type));

for scen_i = 1:length(all_scenario_names)

    FIP_all_days_mean_change_by_land(:,:,scen_i,:) = FIP_all_days_mean_by_land_type(:,:,scen_i,:) - FIP_all_days_mean_by_land_type(:,:,2,:);

end

%% make histograms by land type

num_bins = 20;
min_bin_boarder = 0;
max_bin_boarder = 2000;
bin_boards = linspace(min_bin_boarder,max_bin_boarder,num_bins);

y_min = 0;
y_max = 0.06;

    figure('Position', [100, 100, 800, 200]);
    set(gcf,'color',[1 1 1]);
    set(0, 'DefaultAxesFontSize',12);
    set(0,'defaultAxesFontName', 'helvetica')
    hold on

    for land_cat_i = 1:length(land_type_labels)

        subplot(1,3,land_cat_i)
        hold on

            data_today = squeeze(FIP_all_days_mean_by_land_type(:,:,2,land_cat_i));
            data_RCP45_2050_treat = squeeze(FIP_all_days_mean_by_land_type(:,:,5,land_cat_i));
            data_RCP45_2050_no_treat = squeeze(FIP_all_days_mean_by_land_type(:,:,6,land_cat_i));

            h1 = histogram(data_today,bin_boards,...
                           'FaceColor','k',...
                           'EdgeColor','k',...
                           'EdgeAlpha',0.3,...
                           'FaceAlpha',0.3,...
                           'Normalization',...
                           'probability');

            h2 = histogram(data_RCP45_2050_treat,bin_boards,...
                           'FaceColor','b',...
                           'EdgeColor','b',...
                           'EdgeAlpha',0.3,...
                           'FaceAlpha',0.3,...
                           'Normalization',...
                           'probability');

            h3 = histogram(data_RCP45_2050_no_treat,bin_boards,...
                           'FaceColor','r',...
                           'EdgeColor','r',...
                           'EdgeAlpha',0.3,...
                           'FaceAlpha',0.3,...
                           'Normalization',...
                           'probability');

            xline(mean(data_today(:),"omitnan"),'-k','LineWidth',2)
            xline(mean(data_RCP45_2050_treat(:),"omitnan"),'-b','LineWidth',2)
            xline(mean(data_RCP45_2050_no_treat(:),"omitnan"),'-r','LineWidth',2)

            if land_cat_i == 1; legend(["Today" "Universal Fuel Reduction" "No Fuel Reduction"],"FontSize",7); end

            title(land_type_labels(land_cat_i))

            if land_cat_i == 1; ylabel("Relative Frequency"); end

            xlabel("Fire Intensity Potential (MW)")

    end

    sgtitle("2050 Under SSP2-4.5")


%% make all rank plots

    smooth_window = 100;
    subsample_step = 50;

        all_scenario_names = ["Today, fuel reduction",...
        "Today, no fuel reduction",...
        "2050, SSP1-2.6 & universal fuel reduction",...
        "2050, SSP1-2.6 & no fuel reduction",...
        "2050, SSP2-4.5 & universal fuel reduction",...
        "2050, SSP2-4.5 & no fuel reduction",...
        "2090, SSP1-2.6 & universal fuel reduction",...
        "2090, SSP1-2.6 & no fuel reduction",...
        "2090, SSP2-4.5 & universal fuel reduction",...
        "2090, SSP2-4.5 & no fuel reduction"];
    
    inds_to_plot = [6 4 5 3 2];
    
    all_scenario_names_plot = all_scenario_names(inds_to_plot);

    ranked_var_to_plot = S_and_B_broad_cat;
    ranked_var_to_plot_lin = ranked_var_to_plot(:);
    [ranked_var_sort_vals,ranked_var_sort_inds] = sort(ranked_var_to_plot_lin,"ascend");

    ranked_var_to_plot_lin_sorted = ranked_var_to_plot_lin(ranked_var_sort_inds);
    ranked_var_to_plot_lin_sorted_sub = ranked_var_to_plot_lin_sorted(1:subsample_step:end);

    length_of_smoothed_series = length(1:subsample_step:numel(wrf_lat_2d));

    smoothed_series_10_scens = NaN(length_of_smoothed_series,length(inds_to_plot));

    smoothed_series_targeted_10_scens = NaN(length_of_smoothed_series,length(inds_to_plot));

    for scens_i = 1:length(inds_to_plot)

            FIP_to_plot = FIP_all_days_mean(:,:,inds_to_plot(scens_i));
            FIP_to_plot_lin = FIP_to_plot(:);
            
            FIP_to_plot_lin_sorted = FIP_to_plot_lin(ranked_var_sort_inds);
            FIP_to_plot_lin_sorted_sub = FIP_to_plot_lin_sorted(1:subsample_step:end);
            
            FIP_to_plot_lin_sorted_sub_smooth = smooth(ranked_var_to_plot_lin_sorted_sub,FIP_to_plot_lin_sorted_sub,smooth_window,'rlowess');
    
            smoothed_series_10_scens(:,scens_i) = FIP_to_plot_lin_sorted_sub_smooth;

            FIP_to_plot = FIP_all_days_mean_targeted_treat(:,:,inds_to_plot(scens_i));
            FIP_to_plot_lin = FIP_to_plot(:);
            
            FIP_to_plot_lin_sorted = FIP_to_plot_lin(ranked_var_sort_inds);
            FIP_to_plot_lin_sorted_sub = FIP_to_plot_lin_sorted(1:subsample_step:end);
            
            FIP_to_plot_lin_sorted_sub_smooth = smooth(ranked_var_to_plot_lin_sorted_sub,FIP_to_plot_lin_sorted_sub,smooth_window,'rlowess');
    
            smoothed_series_targeted_10_scens(:,scens_i) = FIP_to_plot_lin_sorted_sub_smooth;

    end

    colors_to_plot_1 = {[0.6350 0.0780 0.1840],...
                       [0.8500 0.3250 0.0980],...
                       [0.3010 0.7450 0.9330],...
                       [0 0.4470 0.7410],...
                       [0 0 0]};

    colors_to_plot_2 = {[0.6350 0.0780 0.1840],...
                       [0.8500 0.3250 0.0980],...
                       [0.4940 0.1840 0.5560],...
                       [0.4660 0.6740 0.1880],...
                       [0 0 0]};

    linwidths = [2 2 2 2 4];

    figure('Position', [100, 100, 600, 600]);
    set(gcf,'color',[1 1 1]);
    set(0, 'DefaultAxesFontSize',14);
    set(0,'defaultAxesFontName', 'helvetica')
    hold on

    xline(1)
    xline(3.5)
    xline(4.5)

    for scens_i = 1:length(inds_to_plot)

        plot(ranked_var_to_plot_lin_sorted_sub,smoothed_series_10_scens(:,scens_i),'color',colors_to_plot_1{scens_i},'LineWidth',linwidths(scens_i))

        plot(ranked_var_to_plot_lin_sorted_sub,smoothed_series_targeted_10_scens(:,scens_i),'color',colors_to_plot_2{scens_i},'LineWidth',linwidths(scens_i))

    end

    xlim([1 5])
    ylim([100 800])

    xlabel("Fuel Category Index")
    ylabel("Average Fire Intensity Potential (MW)")

%% make figure 1

hour_inds_to_plot = [1 2 3];
scen_ind_to_plot = 2;

subplotRows = 1;
subplotCols = 3;
padding = 0.01;
subplotWidth = (1 - (subplotCols + 1) * padding) / subplotCols;
subplotHeight = (1 - (subplotRows + 1) * padding) / subplotRows;

    FigHandle = figure('Position', [100, 100, 1000, 600]);
    set(gcf,'color',[1 1 1]);
    set(0, 'DefaultAxesFontSize',14);
    set(0,'defaultAxesFontName', 'helvetica')

for hour_to_assess_i = 1:length(hour_inds_to_plot)

                left = padding + (mod(hour_to_assess_i - 1, subplotCols)) * (subplotWidth + padding);
                bottom = 1 - (ceil(hour_to_assess_i / subplotCols)) * (subplotHeight + padding);
                subplot('Position', [left bottom subplotWidth subplotHeight]);
                hold on;

                axesm('robinson',...
                'Frame', 'off',...
                'Grid', 'off',...
                'maplatlim',[min(min(wrf_lat_2d)) max(max(wrf_lat_2d))-0.3],...
                'maplonlim',[min(min(wrf_lon_2d))+1.4 max(max(wrf_lon_2d))-0.4])
                tightmap

                map_now = squeeze(FIP_all_days(:,:,scen_ind_to_plot,hour_to_assess_i));

                pcolorm(wrf_lat_2d,wrf_lon_2d,map_now,'LineStyle','none');

                clim([0 2500])
                geoshow([S.Lat], [S.Lon], 'Color', 'black');

                map_mean = mean(map_now(:),"omitnan");

                title(strcat(datestr(top_FRP_hours_seperated(read_in_FRP_top_hours_inds(hour_to_assess_i)),'dd-mmm-yyyy HH:MM'),', Mean FIP =',num2str(round(FIP_map_means(scen_ind_to_plot,hour_to_assess_i))),' MW'))

            datetime_hour_of_map = top_FRP_hours_seperated(read_in_FRP_top_hours_inds(hour_to_assess_i));

            good_hour_ind = find(viirs_range_hourly_datetime_array == datetime_hour_of_map);

            fire_lats_this_hour = lats_of_fires_by_hour{good_hour_ind};
            fire_lons_this_hour = lons_of_fires_by_hour{good_hour_ind};
            fire_FRPs_this_hour = FRPs_of_fires_by_hour{good_hour_ind};

            numel(fire_lats_this_hour)

            scatterm(fire_lats_this_hour,...
            fire_lons_this_hour,...
            0.0005.*fire_FRPs_this_hour,...
            'o','filled','MarkerFaceColor',"magenta",'MarkerEdgeColor',"magenta",'MarkerFaceAlpha',0.5)
            colormap turbo
end