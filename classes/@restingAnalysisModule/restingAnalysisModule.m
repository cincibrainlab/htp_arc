classdef restingAnalysisModule < handle
    % Object ext. for eegDataClass
    
    % standard interfaces for view/figure code
    % methods to generate figures
    
    properties (Abstract)
    end
    
    properties
        % gpu acceleration properties
        gpuOn % 0 or 1; indicates compute capable GPU card is present
        
        subj_field % pairing info
        subj_gender
        subj_age
        subj_trials
        
        % result storage of resting analyses
        freqTable
        pntsTable
                
        rest_abs_power
        rest_rel_power
        rest_fft_phase
        rest_abs_hz
        rest_rel_hz
        
        rest_abs_power_band_average_trials
        rest_rel_power_band_average_trials
        
        rest_wavelet_complex
        rest_hilbert_complex
        
        rest_peakloc
        rest_dbwpli
        rest_plv
        rest_modInd
        rest_comodulogram
        
        rest_mi_amp_phase
        rest_mi_phase
        rest_mi_amp
        
        degree
        density
        strength
        cluster_coef1
        cluster_coef2
        transitivity1
        transitivity2
        modularity1
        modularity2
        efficiency1
        efficiency2
        assortativity1
        assortativity2
        betweencentrality1
        betweencentrality2
        eigencentrality1
        eigencentrality2
        
    end
    
    methods (Abstract)
    end
    
    methods (Static)
        %construct points table based on frequency & 
        %segment length in seconds
        function pnts = hz2pnts(hz, epoch_length)
            pnts = epoch_length * hz + 1;
        end
        
        
        function corr_rho = SpearmanCorrelation2(rel_target_band, rel_gamma_band)
            [rho, ~] = corr(rel_target_band, rel_gamma_band, 'Type', 'Spearman');
            corr_rho = mean(rho);
        end
        
        
        function corr_rho = SpearmanCorrelation(rel_target_band, rel_gamma_band)
            cluster_value = mean(rel_target_band, 2); % 1* trials
            [rho, ~] = corr(repmat(cluster_value, [1 size(rel_gamma_band,2)]), ...
                                rel_gamma_band, 'Type', 'Spearman');
            corr_rho = rho(1, :);
        end
            
        
        function z_corr_rho = FisherZtrans(r)
            % a point-by-point calculation
            z_corr_rho = .5 * log((1+r) ./ (1-r));
        end
        
        
        function amp_trans = logTransform( amp )
            % no worry for support boundary
            amp_trans = log(amp);
        end
        
        
        function [Hx, Hy] = bandwidth( arg1, arg2, flag )
            % x-amplitude, y-phase 
            if length(arg1) == length(arg2)
                M = length(arg1);
            else
                cprintf('err', '\n\nERROR: error data length.\n');
            end
            if strcmp(flag,'mix')
                Hx = M^(-1/6)*(1/.6745)*mad(arg1); % linear bandwidth
                Hy = M^(-1/6)*sqrt(2*(1-abs(mean(exp(1j*arg2))))); % circular bandwidth
            elseif strcmp(flag,'linear')
                Hx = M^(-1/6)*(1/.6745)*mad(arg1);
                Hy = M^(-1/6)*(1/.6745)*mad(arg2);
            elseif strcmp(flag,'circular')
                Hx = M^(-1/6)*sqrt(2*(1-abs(mean(exp(1j*arg1)))));
                Hy = M^(-1/6)*sqrt(2*(1-abs(mean(exp(1j*arg2)))));
            else
                cprintf('err', '\n\nERROR: error processing bandwidth.\n');
            end
        end
		
		
		function [Hx, Hy] = bandwidth_2d( arg1, arg2, flag )
			% 02/04 from Kyle
		    %x-amplitude, y-phase
		    if size(arg1,1) == size(arg2,1)
			    M = size(arg1,1);
		    else
				cprintf('err', '\n\nERROR: error data length.\n');
			end
			if strcmp(flag, 'mix')
			    Hx = M^(-1/6)*(1/.6745)*mad(arg1,0,1);  %linear bandwidth
			    Hy = M^(-1/6)*sqrt(2*(1-abs(mean(exp(1j*arg2)))));  %circular bandwidth
		    elseif strcmp(flag, 'linear')
			    Hx = M^(-1/6)*(1/.6745)*mad(arg1,0,1);
			    Hy = M^(-1/6)*(1/.6745)*mad(arg2,0,1);
		    elseif strcmp(flag, 'circular')
			    Hx = M^(-1/6)*sqrt(2*(1-abs(mean(exp(1j*arg1)))));
			    Hy = M^(-1/6)*sqrt(2*(1-abs(mean(exp(1j*arg2)))));
		    else
			    cprintf('err', '\n\nERROR: error processing bandwidth.\n');
		   end
		end
		
        
        
        function ldensity = linearKDE ( amp_trans, Hx )
            % linear desity
            ind = sort(amp_trans);
% gpu conversion
            [ldensity,~] = ksdensity(amp_trans, ind, 'Bandwidth', Hx);
%             [ldensity,~] = ksdensity(gather(amp_trans), gather(ind), 'Bandwidth', gather(Hx));
%             figure;plot(ind,ldensity,'o-')
%             xlabel('log(amplitude)');ylabel('density');
        end


        function circular_mod = circularKDE ( phase, Hy )
            % circular density
            phase_replicates = [phase-2*pi phase phase+2*pi];
            circular = ksdensity(phase_replicates, sort(phase), 'Bandwidth', Hy);
%             circular = ksdensity(gather(phase_replicates), gather(sort(phase)), 'Bandwidth', gather(Hy));
            circular_mod = 3*circular;
%             figure;plot(sort(phase),circular_mod,'o-')
%             xlabel('phase');ylabel('density');
        end
        
        
        function planar = planarKDE ( amp_trans1, amp_trans2, Hx, Hy )
            % planar density
            dat = [amp_trans1' amp_trans2']; % 2-column mat
%             planar = ksdensity(gather(dat), gather(dat), 'Bandwidth', gather([Hx Hy])); 
            planar = ksdensity(dat, dat, 'Bandwidth', [Hx Hy]); 
%             figure;scatter3(amp_trans1, amp_trans2, planar)
%             xlabel('amplitude1');ylabel('amplitude2');zlabel('density');
%             view(2)
        end
        
        
        function cylindrical_mod = cylindricalKDE ( amp_trans, phase, Hx, Hy )
            % cylindrical density
            % 1:amplitude, 2:phase, 3:H_amp, 4:H_phase
            amp_replicates = [amp_trans amp_trans amp_trans];
            phase_replicates = [phase-2*pi phase phase+2*pi]; 
            dat = [amp_replicates' phase_replicates']; % 2-column mat
            ind = [amp_trans' phase']; % 2-column mat
%             cylindrical = ksdensity(gather(dat), gather(ind), 'Bandwidth', gather([Hx Hy])); 
            cylindrical = ksdensity(dat, ind, 'Bandwidth', [Hx Hy]); 
            cylindrical_mod = 3*cylindrical;
%             figure;scatter3(amp_trans, phase, cylindrical_mod)
%             xlabel('log(amplitude)');ylabel('phase');zlabel('density');
%             view(2)
        end
        
        
        function toroidal_mod = toroidalKDE ( phase1, phase2, Hx, Hy )
            % toroidal density
            phase1_replicates = [phase1-2*pi phase1 phase1+2*pi];
            phase2_replicates = [phase2-2*pi phase2 phase2+2*pi]; 
            dat = [phase1_replicates' phase2_replicates']; % 2-column mat
            ind = [phase1' phase2']; % 2-column mat
            toroidal = ksdensity(dat, ind, 'Bandwidth', [Hx Hy]); 
            toroidal_mod = 9*toroidal;
%             figure;scatter3(phase1, phase2, toroidal_mod)
%             xlabel('phase1');ylabel('phase2');zlabel('density');
%             view(2)
        end
              
        
        function mi = MI(ldensity, circular_cut, cylindrical_cut)
            lentropy = -sum(ldensity.*log(ldensity));
            centropy = -sum(circular_cut.*log(circular_cut));
            jentropy = -sum(cylindrical_cut.*log(cylindrical_cut));
            mi = lentropy + centropy - jentropy;
        end
        
    end
    
    methods
        
        function obj = restingAnalysisModule(  )
            % constructor
            obj.gpuOn = 0; % GPU off by default
        end
        
        
    end
end
