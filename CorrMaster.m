function GG = CorrMaster(memtype,corrtype,cutoff,varargin)
% FFT Convolution Wrapper for Two-Point Statistics Calculations. 
% A by-product of ongoing computational materials science research 
% at MINED@Gatech.(http://mined.gatech.edu/)
%
% This function calculates VECTOR COUNTS for utilization in 2-point 
% statistics calculations. A proper statistics calculation would use this 
% function TWICE: once for the numerator and once for the denominator. 
%
% GG = CorrMaster('full','auto',cutoff,H1) calculates the vector counts
% for the auto correlation of H1,with a maximum vector length of "cutoff". 
%
% GG = CorrMaster('full','cross',cutoff,H1,H2) calculates the vector 
% counts for the  cross correlation of H1 and H2, with a maximum vector 
% length of "cutoff". 
% 
% GG = CorrMaster('patched','auto',cutoff,DataFile,winmulti) calculates
% the vector counts for the auto correlation of H1,with a maximum vector 
% length of "cutoff". However this version uses the patching convolution 
% method to save memory, sacrificing computation time. A balance between 
% memory and computation time can be struck using the winmulti parameter.
% A winmulti of 1 will result in the minimum memory calculation, and will 
% take considerably (sometimes an order of magnitude) longer to calculate, 
% whereas a winmulti of 3 will take roughly 8 gb of memory, resulting in 
% only twice the computational time for most practical cases.
%
% GG = CorrMaster('patched','cross',cutoff,DataFile,winmulti,DataFile2)
% calculates the vector counts for the cross correlation of H1 and H2, 
% with a maximum vector length of "cutoff". However this version uses the 
% patching convolution method to save memory, sacrificing computation time. 
% A balance between memory and computation time can be struck using the 
% winmulti parameter. A winmulti of 1 will result in the minimum memory 
% calculation, and will take considerably (sometimes an order of magnitude)
% longer to calculate, whereas a winmulti of 3 will take roughly 11 gb of 
% memory, resulting in only twice the computational time for most practical 
% cases.
%
% If 'patched' mode is used, "DataFile" and "DataFile2" are supposed to be
% in the following format:
% "/path/to/DataFile/DataFile.mat/ArrayName"
% where "/path/to/DataFile/DataFile.mat" is the full path to the datafile
% to be used in the calculation, and ArrayName is the name of the array
% object to be used in that file. Otherwise, the whole string in "DataFile"
% or "DataFile2" will be assumed as the path to the ".mat" file, and
% ArrayName is defaulted to "H1".
% 
% Author: Ahmet Cecen
% Contact: ahmetcecen@gmail.com
% 
% Update: Sep. 30, 2016
% Added comments.
% -- Yue Sun
%
% Update: Dec. 8, 2017
% Changed the behavior of cutoff. Now cutoff = n will result in (2n+1) 
% elements on each dimension.
% -- Yue Sun

switch memtype
	
	case 'full'
	
		switch corrtype 

			case 'auto'
                
				H1 = varargin{1};
                
                H1 = fftn(H1);
                H1 = H1.*conj(H1);
                H1 = ifftn(H1);
                H1 = fftshift(H1);
                
                GG = H1;
				
				if ismatrix(H1)
					GG = GG((floor((size(GG,1)/2)+1)-cutoff):(floor((size(GG,1)/2)+1)+cutoff),...
								(floor((size(GG,2)/2)+1)-cutoff):(floor((size(GG,2)/2)+1)+cutoff));
				elseif ndims(H1)==3
					GG = GG((floor((size(GG,1)/2)+1)-cutoff):(floor((size(GG,1)/2)+1)+cutoff),...
								(floor((size(GG,2)/2)+1)-cutoff):(floor((size(GG,2)/2)+1)+cutoff),...
								(floor((size(GG,3)/2)+1)-cutoff):(floor((size(GG,3)/2)+1)+cutoff));
				else
					error('Incorrect Number of Dimensions!');
				end
				
			case 'cross'
                
				H1 = varargin{1};
				H2 = varargin{2};

                H1 = fftn(H1);
                H1 = conj(H1);
                H2 = fftn(H2);
                H1 = H1.*H2;
                clearvars H2;
                H1 = ifftn(H1);
                H1 = fftshift(H1);
                
                GG = H1;		
							
				if ismatrix(H1)
					GG = GG((floor((size(GG,1)/2)+1)-cutoff):(floor((size(GG,1)/2)+1)+cutoff),...
								(floor((size(GG,2)/2)+1)-cutoff):(floor((size(GG,2)/2)+1)+cutoff));
				elseif ndims(H1)==3
					GG = GG((floor((size(GG,1)/2)+1)-cutoff):(floor((size(GG,1)/2)+1)+cutoff),...
								(floor((size(GG,2)/2)+1)-cutoff):(floor((size(GG,2)/2)+1)+cutoff),...
								(floor((size(GG,3)/2)+1)-cutoff):(floor((size(GG,3)/2)+1)+cutoff));
				else
					error('Incorrect Number of Dimensions!');
				end							
							
							
		end
		
	case 'patched'
	
		% Window Indexing Variables
		DataFile=varargin{1};
		winmulti=varargin{2};
        
        [DataFile, ArrayName] = sep_filename(DataFile);
		
        m=matfile(DataFile);
		Hsize=size(m, ArrayName);
		
        % If 3D
        if length(Hsize)==3
			DataSize=Hsize-[2*cutoff,2*cutoff,2*cutoff];
			nz=DataSize(3);		
			ztra=mod(nz,(winmulti*(cutoff+1)));		
			zbc=floor(nz/(winmulti*(cutoff+1)));
			zbuf=floor(ztra/zbc);
			zwinsize=(winmulti*(cutoff+1))+zbuf;
			zbuftra=mod(ztra,zbuf);
			zwinlist=[zwinsize*ones(zbc-1,1);(zwinsize+zbuftra)];
			GG = zeros((1+2*cutoff),(1+2*cutoff),(1+2*cutoff)); 
        end

        if length(Hsize)==2
            DataSize=Hsize-[2*cutoff,2*cutoff];
			GG = zeros((1+2*cutoff),(1+2*cutoff)); 
        end
	
		nx=DataSize(1);
		ny=DataSize(2);

		xtra=mod(nx,(winmulti*(cutoff+1)));
		ytra=mod(ny,(winmulti*(cutoff+1)));

		xbc=floor(nx/(winmulti*(cutoff+1)));
		ybc=floor(ny/(winmulti*(cutoff+1)));

		xbuf=floor(xtra/xbc);
		ybuf=floor(ytra/ybc);

		xwinsize=(winmulti*(cutoff+1))+xbuf;
		ywinsize=(winmulti*(cutoff+1))+ybuf;

		xbuftra=mod(xtra,xbuf);
		ybuftra=mod(ytra,ybuf);

		xwinlist=[xwinsize*ones(xbc-1,1);(xwinsize+xbuftra)];
		ywinlist=[ywinsize*ones(ybc-1,1);(ywinsize+ybuftra)];
		
        % Progress Bar Initialize
        progress=0;
        reverseStr = '';
        
		% Main Loop
		
		switch corrtype 
		
			case 'auto'
				% Memory Map
                
				if length(Hsize)==2
				
					for xx=1:xbc
						for yy=1:ybc
                            
                            tic;
                                
                            progress=progress+1;
							
							% Grab H1 Window
							HH1 = m.(ArrayName)(((sum(xwinlist(1:xx)))-xwinlist(xx)+1):(sum(xwinlist(1:xx))+2*cutoff),...
								((sum(ywinlist(1:yy)))-ywinlist(yy)+1):(sum(ywinlist(1:yy))+2*cutoff));
								
							% Create H2 Mask
							MM1 = padarray(ones(xwinlist(xx),ywinlist(yy)),[cutoff,cutoff],0,'both');        
							
							% Compute Convolution
							G = fftshift(ifftn(fftn(HH1).*conj(fftn(HH1.*MM1))));
							
							G = G((floor((size(G,1)/2)+1)-cutoff):(floor((size(G,1)/2)+1)+cutoff),...
								(floor((size(G,2)/2)+1)-cutoff):(floor((size(G,2)/2)+1)+cutoff));
						 
							GG = GG + G;     
                            
                            if xx==1 && yy==1
                                est=toc;
                                fprintf('Estimated Completion = %.2f minutes - ',(xbc*ybc-1)*est/60);
                            end              
                            
                            % Progress Bar
                            fprintf(reverseStr);

                            msg=fprintf('Progress = %.2f %%',100*progress/(xbc*ybc));                                
                            reverseStr = repmat(sprintf('\b'), 1, msg);  
                            
                            if xx==xbc && yy==ybc
                                fprintf('\n');
                            end
			
						end
					end
								
				elseif length(Hsize)==3
				
					for xx=1:xbc
						for yy=1:ybc
							for zz=1:zbc
                                
                                tic;
                                
                                progress=progress+1;
							
								% Grab H1 Window
								HH1 = m.(ArrayName)(((sum(xwinlist(1:xx)))-xwinlist(xx)+1):(sum(xwinlist(1:xx))+2*cutoff),...
									((sum(ywinlist(1:yy)))-ywinlist(yy)+1):(sum(ywinlist(1:yy))+2*cutoff),...
									((sum(zwinlist(1:zz)))-zwinlist(zz)+1):(sum(zwinlist(1:zz))+2*cutoff));
									
								% Create H2 Mask
								MM1 = padarray(ones(xwinlist(xx),ywinlist(yy),zwinlist(zz)),[cutoff,cutoff,cutoff],0,'both');        
								
								% Compute Convolution
								G = fftshift(ifftn(fftn(HH1).*conj(fftn(HH1.*MM1))));
								
								G = G((floor((size(G,1)/2)+1)-cutoff):(floor((size(G,1)/2)+1)+cutoff),...
									(floor((size(G,2)/2)+1)-cutoff):(floor((size(G,2)/2)+1)+cutoff),...
									(floor((size(G,3)/2)+1)-cutoff):(floor((size(G,3)/2)+1)+cutoff));
							 
								GG = GG + G;  
                                
                                if xx==1 && yy==1 && zz==1
                                    est=toc;
                                    fprintf('Estimated Completion = %.2f minutes - ',(xbc*ybc*zbc-1)*est/60);
                                end
                                
                                % Progress Bar
                                fprintf(reverseStr);
                                msg=fprintf('Progress = %.2f %%\n',100*progress/(xbc*ybc*zbc));                                
                                reverseStr = repmat(sprintf('\b'), 1, msg);
                                
                                if xx==xbc && yy==ybc && zz==zbc
                                    fprintf('\n');
                                end
				
							end
						end
					end
				
				else
					error('Incorrect Number of Dimensions!');

				end
				
			case 'cross'
				% Memory Map
				DataFile2=varargin{3};
                
                [DataFile2, ArrayName2] = sep_filename(DataFile2);
                
				n=matfile(DataFile2);
				
				
				if length(Hsize)==2
				
					for xx=1:xbc
						for yy=1:ybc
                            
                            tic;
                                
                            progress=progress+1;
							
							% Grab H1 Window
							HH1 = m.(ArrayName)(((sum(xwinlist(1:xx)))-xwinlist(xx)+1):(sum(xwinlist(1:xx))+2*cutoff),...
								((sum(ywinlist(1:yy)))-ywinlist(yy)+1):(sum(ywinlist(1:yy))+2*cutoff));
								
							% Grab H2 Window
							HH2 = n.(ArrayName2)(((sum(xwinlist(1:xx)))-xwinlist(xx)+1):(sum(xwinlist(1:xx))+2*cutoff),...
								((sum(ywinlist(1:yy)))-ywinlist(yy)+1):(sum(ywinlist(1:yy))+2*cutoff));
								
							% Create H2 Mask
							MM1 = padarray(ones(xwinlist(xx),ywinlist(yy)),[cutoff,cutoff],0,'both');

							% Compute Convolution
							G = fftshift(ifftn(fftn(HH1).*conj(fftn(HH2.*MM1))));
							
							G = G((floor((size(G,1)/2)+1)-cutoff):(floor((size(G,1)/2)+1)+cutoff),...
								(floor((size(G,2)/2)+1)-cutoff):(floor((size(G,2)/2)+1)+cutoff));
						 
							GG = GG + G; 
                            
                            if xx==1 && yy==1
                                est=toc;
                                fprintf('Estimated Completion = %.2f minutes - ',(xbc*ybc-1)*est/60);
                            end                            

                            % Progress Bar
                            fprintf(reverseStr);

                            msg=fprintf('Progress = %.2f %%',100*progress/(xbc*ybc));                                
                            reverseStr = repmat(sprintf('\b'), 1, msg);
                            
                            if xx==xbc && yy==ybc
                                fprintf('\n');
                            end
                            
						end
					end					
				
				elseif length(Hsize)==3
				
					for xx=1:xbc
						for yy=1:ybc
							for zz=1:zbc
                                
                                tic;
                                
                                progress=progress+1;
							
								% Grab H1 Window
								HH1 = m.(ArrayName)(((sum(xwinlist(1:xx)))-xwinlist(xx)+1):(sum(xwinlist(1:xx))+2*cutoff),...
									((sum(ywinlist(1:yy)))-ywinlist(yy)+1):(sum(ywinlist(1:yy))+2*cutoff),...
									((sum(zwinlist(1:zz)))-zwinlist(zz)+1):(sum(zwinlist(1:zz))+2*cutoff));
									
								% Grab H2 Window
								HH2 = n.(ArrayName2)(((sum(xwinlist(1:xx)))-xwinlist(xx)+1):(sum(xwinlist(1:xx))+2*cutoff),...
									((sum(ywinlist(1:yy)))-ywinlist(yy)+1):(sum(ywinlist(1:yy))+2*cutoff),...
									((sum(zwinlist(1:zz)))-zwinlist(zz)+1):(sum(zwinlist(1:zz))+2*cutoff));
									
								% Create H2 Mask
								MM1 = padarray(ones(xwinlist(xx),ywinlist(yy),zwinlist(zz)),[cutoff,cutoff,cutoff],0,'both');

								% Compute Convolution
								G = fftshift(ifftn(fftn(HH1).*conj(fftn(HH2.*MM1))));
								
								G = G((floor((size(G,1)/2)+1)-cutoff):(floor((size(G,1)/2)+1)+cutoff),...
									(floor((size(G,2)/2)+1)-cutoff):(floor((size(G,2)/2)+1)+cutoff),...
									(floor((size(G,3)/2)+1)-cutoff):(floor((size(G,3)/2)+1)+cutoff));
							 
								GG = GG + G;      
  
                                if xx==1 && yy==1 && zz==1
                                    est=toc;
                                    fprintf('Estimated Completion = %.2f minutes - ',(xbc*ybc*zbc-1)*est/60);
                                end                                
                                
                                % Progress Bar
                                fprintf(reverseStr);

                                msg=fprintf('Progress = %.2f %%',100*progress/(xbc*ybc*zbc));                                
                                reverseStr = repmat(sprintf('\b'), 1, msg);   
                                
                                if xx==xbc && yy==ybc && zz==zbc
                                    fprintf('\n');
                                end
								
							end
						end
					end				
				
				else
					error('Incorrect Number of Dimensions!');				
				end
				
		end
end

end

%% internal function to seperate data array name from data file name
function [filename, arrayname] = sep_filename(s)

sep = strfind(s, '.mat');
if isempty(sep)
    filename = s;
    arrayname = 'H1';
    return;
end

filename = s(1:(sep(end)+4));
if length(s) > sep(end)+4
    arrayname = s(sep(end)+5:end);
else
    arrayname = 'H1';
end

    
end
