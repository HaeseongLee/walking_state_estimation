function cs_filtered = csFilter(raw_cs, window)
% raw_cs : no filtered output from the discriminator
% window: kind of buffer size(or time delay)

    cs_filtered = zeros(length(raw_cs),1);
    for i = window:length(raw_cs)    
        roi = raw_cs(i-window+1:i,1);     
        if length(find(roi~=0)) == window
            cs_filtered(i) = raw_cs(i);
        end
    end
end