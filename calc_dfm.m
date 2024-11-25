function [DFM_hourly_time_series] = calc_dfm(T_K_hourly_time_series,RH_perc_hourly_time_series,precip_mm_hourly_time_series,DFM_hour)

DFM_hourly_time_series = NaN(size(T_K_hourly_time_series));
            
%run hourly model

    %drying equilibrium at each time step (for when fuel moisture is greater than equilibrium (as defined by the atmopshere) and thus
    %the fuel is drying) page 9
        Ed = 0.924.*RH_perc_hourly_time_series.^(0.679)+0.000499.*exp(0.1.*RH_perc_hourly_time_series)+0.18.*(21.1+273.15-T_K_hourly_time_series).*(1-exp(-0.115.*RH_perc_hourly_time_series));

    %wetting equilibrium at each time step (for when fuel moisture is less than equilibrium (as defined by the atmopshere) and thus
    %the fuel is wetting) page 9
        Ew = 0.618.*RH_perc_hourly_time_series.^(0.753)+0.000454.*exp(0.1.*RH_perc_hourly_time_series)+0.18.*(21.1+273.15-T_K_hourly_time_series).*(1-exp(-0.115.*RH_perc_hourly_time_series));
        
        DFM_hourly_time_series(1) = (Ed(1) + Ew(1))./2;
            
            %define some paramaters

            dt = 1;

            tL = DFM_hour;

            %for rain
            S = 250; % percent
            r0 = 0.05; %mm/hr
            rs = 8.0; %mm/r

            tr = 1.4*DFM_hour;
    
         for hourly_ti = 2:length(DFM_hourly_time_series)

                %starting at equalibrium
                    previous_m = DFM_hourly_time_series(hourly_ti-1);
                    previous_Ed = Ed(hourly_ti-1);
                    previous_Ew = Ew(hourly_ti-1);
                    previous_precip =  precip_mm_hourly_time_series(hourly_ti-1);

                    %if no rain (or precip less than r0 threshold)

                    if previous_precip < r0

                        %equation 3 page 9

                        if previous_m > previous_Ed

                            next_m = previous_m + dt.*(previous_Ed-previous_m)./(tL);

                        end
                        if previous_Ed >= previous_m && previous_m >= previous_Ew

                            next_m = previous_m;

                        end
                        if previous_m < previous_Ew

                            next_m = previous_m + dt.*(previous_Ew-previous_m)./(tL);

                        end

                        DFM_hourly_time_series(hourly_ti) = next_m;

                    end

                    if previous_precip >= r0

                        %equation 4

                        next_m = previous_m + (dt.*(S - previous_m)./tr).*(1-exp(-((previous_precip-r0)./rs)));

                        DFM_hourly_time_series(hourly_ti) = next_m;

                    end
         end

