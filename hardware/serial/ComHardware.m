% modified by FPonce
classdef ComHardware < handle
    %MARGOHARDWARE Summary of this class goes here
    %   Detailed explanation goes here

    properties
        light SerialDevice;
        aux SerialDevice;
        ports cell;
        devices SerialDevice;
        settings;
        statuses SerialDeviceStatuses;
    end

    properties(Constant, Access = private)
        HANDSHAKE logical = [true true false false true false true];
        HANDSHAKE_PANEL uint8 = 2;
        HANDSHAKE_LEVEL uint8 = 2;
        HANDSHAKE_RETRIES double = 3;
        HANDSHAKE_TIMEOUT double = 1.0;
    end

    methods
        function this = ComHardware()
            this.updatePortsList();
        end

        % function findDevices(this)
        %     % Detect available ports
        %     this.closeOpenConnections();
        %     this.updatePortsList();
        %     this.light = SerialDevice.empty();  % reset before scanning
        %     for i = 1:size(this.ports, 1)
        %         this.devices(i) = SerialDevice(this.ports{i});
        %         isSuccessful = ComHardware.handshakeDevice(this.devices(i));
        %         if isSuccessful
        %             this.light = this.devices(i);
        %             this.light.open();
        %             break;  % stop scanning once found
        %         end
        %     end
        % end
        function findDevices(this)
            this.closeOpenConnections();
            pause(2.0);                         % ← increase from 0.5 to 2.0
            this.updatePortsList();
            fprintf('Ports found: %d\n', numel(this.ports));
            for i = 1:numel(this.ports)
                fprintf('  port %d: %s\n', i, this.ports{i});
            end
            this.light = SerialDevice.empty();
            for i = 1:size(this.ports, 1)
                this.devices(i) = SerialDevice(this.ports{i});
                isSuccessful = ComHardware.handshakeDevice(this.devices(i));
                if isSuccessful
                    this.light = this.devices(i);
                    this.light.open();
                    break;
                end
            end
        end


        % function closeOpenConnections(this)
        %     for i = 1:numel(this.devices)
        %         this.devices(i).close();
        %         delete(this.devices(i));            % force destructor to release port
        %     end
        %     this.devices = SerialDevice.empty();    % clear the array
        %     SerialDevice.closeOpenConnections();
        % end

        function closeOpenConnections(this)
            % force delete any open serialport objects directly
            openPorts = serialportfind;
            if ~isempty(openPorts)
                delete(openPorts);
            end
            % also close through the device chain
            for i = 1:numel(this.devices)
                try
                    this.devices(i).close();
                    delete(this.devices(i));
                catch
                end
            end
            this.devices = SerialDevice.empty();
            SerialDevice.closeOpenConnections();
        end

        function updatePortsList(this)
            this.ports = SerialDevice.getAvailablePorts();
            this.ports = this.ports(:);
        end

        function writeLightPanel(this, lightPanel, value)
            if isempty(this.light)
                warning('Cannot write light panel: %s. No light panel set.', lightPanel);
                return;
            end
            if this.light.isClosed()
                this.light.open();
            end
            this.light.write(char([value lightPanel.pinNumber]), 'char');
        end

        function objectToSave = saveobj(this)
            objectToSave = ComHardware();
            objectToSave.ports = this.ports;
        end
    end

    methods(Static, Access = private)
        function isHandshakeSuccessful = handshakeDevice(device)
            isHandshakeSuccessful = false;
            try
                device.open();
                writeData = char([ComHardware.HANDSHAKE_LEVEL ComHardware.HANDSHAKE_PANEL 0 0]);

                for attempt = 1:ComHardware.HANDSHAKE_RETRIES
                    % fprintf('Handshake attempt %d on port %s...\n', attempt, device.port);
                    device.write(writeData, 'char');
                    pause(ComHardware.HANDSHAKE_TIMEOUT);

                    nb = device.bytesAvailable;
                    % fprintf('  bytes available: %d (expected %d)\n', nb, numel(ComHardware.HANDSHAKE));

                    if nb == numel(ComHardware.HANDSHAKE)
                        handshake = device.read(nb, 'uint8');
                        % fprintf('  received: %s\n', num2str(handshake(:)'));
                        % fprintf('  expected: %s\n', num2str(uint8(ComHardware.HANDSHAKE(:))'));
                        if all(handshake(:) == ComHardware.HANDSHAKE(:))
                            isHandshakeSuccessful = true;
                            break;
                        end
                    elseif nb > 0
                        leftover = device.read(nb, 'uint8');
                        fprintf('  flushing %d unexpected bytes: %s\n', nb, num2str(leftover(:)'));
                    end
                end

                device.close();
            catch exception
                fprintf('  EXCEPTION: %s\n', exception.message);
                warning('Serial device handshake failed on port: %s. Skipping port.', device.port);
                device.close();
                isHandshakeSuccessful = false;
            end
        end
    end
end



% classdef ComHardware < handle
%     %MARGOHARDWARE Summary of this class goes here
%     %   Detailed explanation goes here
% 
%     properties
%         light SerialDevice;
%         aux SerialDevice;
%         ports cell;
%         devices SerialDevice;
%         settings;
%         statuses SerialDeviceStatuses;
%     end
% 
%     properties(Constant, Access = private)
%         HANDSHAKE logical = [true true false false true false true];
%         HANDSHAKE_PANEL uint8 = 2;
%         HANDSHAKE_LEVEL uint8 = 2;
%     end
% 
%     methods
%         function this = ComHardware()
%             this.updatePortsList();
%         end
% 
%         function findDevices(this)
% 
%             % Detect available ports
%             this.closeOpenConnections();
%             this.updatePortsList();
% 
%             for i = 1:size(this.ports, 1)
%                 this.devices(i) = SerialDevice(this.ports{i});
%                 isSuccessful = ComHardware.handshakeDevice(this.devices(i));
%                 if isSuccessful
%                     this.light = this.devices(i);
%                     this.light.open();
%                 end
%             end
% 
%         end
% 
%         function closeOpenConnections(this)
%             for i = 1:numel(this.devices)
%                 this.devices(i).close();
%             end
%             SerialDevice.closeOpenConnections();
%         end
% 
%         function updatePortsList(this)
%             this.ports = SerialDevice.getAvailablePorts();
%             this.ports = this.ports(:);
%         end
% 
%         function writeLightPanel(this, lightPanel, value)
% 
%             if isempty(this.light)
%                 warning('Cannot write light panel: %s. No light panel set.', lightPanel);
%                 return;
%             end
% 
%             if this.light.isClosed()
%                 this.light.open();
%             end
% 
%             this.light.write(char([value lightPanel.pinNumber]), 'char');
%         end
% 
%         function objectToSave = saveobj(this)
%             objectToSave = ComHardware();
%             objectToSave.ports = this.ports;
%         end
%     end
% 
%     methods(Static, Access = private)
%         function isHandshakeSuccessful = handshakeDevice(device)
% 
%             try
%                 device.open();
%                 writeData = char([ComHardware.HANDSHAKE_LEVEL ComHardware.HANDSHAKE_PANEL 0 0]);
%                 pause(2);
%                 device.write(writeData, 'char');
%                 pause(0.5);
% 
%                 if device.bytesAvailable ~= numel(ComHardware.HANDSHAKE)
%                     isHandshakeSuccessful = false;
%                     device.close();
%                     return;
%                 end
% 
%                 handshake = device.read(numel(ComHardware.HANDSHAKE), 'uint8');
%                 device.close();
%                 isHandshakeSuccessful = all(handshake(:) == ComHardware.HANDSHAKE(:));
%             catch exception
%                 warning('Serial device handshake failed on port: %s. Skipping port.', device.port);
%                 device.close();
%                 isHandshakeSuccessful = false;
%             end
%         end
%     end
% end
% 
% 
