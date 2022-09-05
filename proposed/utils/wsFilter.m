% This function is for removing impulse-like estimations

function ws_filtered = wsFilter(raw_ws, target_ws, buffer)
% raw_ws : no filtered output from the discriminator
% target_ws : a ws to be filtered
% buffer: buffer size(or time delay)

    ws_filtered = zeros(length(raw_ws),1);
    for j = buffer:length(raw_ws)    
        if raw_ws(j) == target_ws %&& raw_ws(j-1)<= target_ws-1
            roi = raw_ws(j-buffer+1:j);     
            if length(find(roi==target_ws)) == buffer
                ws_filtered(j) = target_ws;
            else
                if(~isempty(find(max(roi)>raw_ws(j), 1)))
                    ws_filtered(j) = raw_ws(j); % falling edge
                else
                    ws_filtered(j) = raw_ws(j)-1; % raising edge
                end                
            end
        else
            ws_filtered(j) = raw_ws(j);
        end
    end
end