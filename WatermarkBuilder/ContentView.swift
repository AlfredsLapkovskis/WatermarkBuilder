//
//  ContentView.swift
//  WatermarkBuilder
//
//  Created by Alfred Lapkovsky on 21/05/2022.
//

import SwiftUI

struct ContentView: View {
    
    @StateObject private var viewModel = ViewModel()
    
    @State private var isFontFamilySheetPresented = false
    @State private var isFontSizeSheetPresented   = false
    
    private var selectedImage: UIImage {
        viewModel.imageData.flatMap { UIImage(data: $0.data) } ?? UIImage()
    }
    
    private var watermarkImage: UIImage {
        if !viewModel.watermarkCustomParams.imageData.data.isEmpty {
            return UIImage(data: viewModel.watermarkCustomParams.imageData.data) ?? UIImage()
        }
        
        return UIImage()
    }
    
    private var uiModeSwitchBinding: Binding<Bool> {
        Binding<Bool> {
            viewModel.controlsType == .customWatermark
        } set: { on in
            viewModel.controlsType = on ? .customWatermark : .textWatermark
        }
    }
    
    private var opacityBinding: Binding<Double> {
        Binding<Double> {
            viewModel.watermarkTextParams.opacity ?? 0
        } set: { opacity in
            viewModel.watermarkTextParams.opacity = opacity
        }
    }
    
    private var rotationAngleBinding: Binding<Double> {
        Binding<Double> {
            Double(viewModel.watermarkTextParams.rotationAngle ?? 0) / 360
        } set: { angle in
            viewModel.watermarkTextParams.rotationAngle = Int(round(angle * 360))
        }
    }
    
    private var densityLevelBinding: Binding<Double> {
        Binding<Double> {
            Double(viewModel.watermarkTextParams.densityLevel?.rawValue ?? ImageProcessor.DensityLevel.medium.rawValue)
        } set: { level in
            viewModel.watermarkTextParams.densityLevel = ImageProcessor.DensityLevel(rawValue: Int(level))
        }
    }
    
    private var colorBinding: Binding<Color> {
        Binding<Color> {
            Color(viewModel.watermarkTextParams.color ?? "000000")
        } set: { color in
            viewModel.watermarkTextParams.color = String(color)
        }
    }
    
    private var shadowOffsetXBinding: Binding<String> {
        Binding<String> {
            viewModel.watermarkTextParams.shadowOffsetX.map { String($0) } ?? ""
        } set: { x in
            viewModel.watermarkTextParams.shadowOffsetX = Int(x)
        }
    }
    
    private var shadowOffsetYBinding: Binding<String> {
        Binding<String> {
            viewModel.watermarkTextParams.shadowOffsetY.map { String($0) } ?? ""
        } set: { y in
            viewModel.watermarkTextParams.shadowOffsetY = Int(y)
        }
    }
    
    private var shadowBlurRadiusBinding: Binding<String> {
        Binding<String> {
            viewModel.watermarkTextParams.shadowBlurRadius.map { String($0) } ?? ""
        } set: { r in
            viewModel.watermarkTextParams.shadowBlurRadius = Int(r)
        }
    }
    
    private var shadowOpacityBinding: Binding<Double> {
        Binding<Double> {
            viewModel.watermarkTextParams.shadowOpacity ?? 0
        } set: { opacity in
            viewModel.watermarkTextParams.shadowOpacity = opacity
        }
    }
    
    private var shadowColorBinding: Binding<Color> {
        Binding<Color> {
            Color(viewModel.watermarkTextParams.shadowColor ?? "000000")
        } set: { color in
            viewModel.watermarkTextParams.shadowColor = String(color)
        }
    }
    
    private var isResultSheetPresentedBinding: Binding<Bool> {
        Binding<Bool> {
            if case .idle = viewModel.requestStatus {
                return false
            }
            
            return true
        } set: { value in
            if !value {
                viewModel.requestStatus = .idle
            }
        }
    }
    
    private var customWatermarkOpacityBinding: Binding<Double> {
        Binding<Double> {
            viewModel.watermarkCustomParams.opacity ?? 0
        } set: { opacity in
            viewModel.watermarkCustomParams.opacity = opacity
        }
    }

    private var customWatermarkRotationAngleBinding: Binding<Double> {
        Binding<Double> {
            Double(viewModel.watermarkCustomParams.rotationAngle ?? 0) / 360
        } set: { angle in
            viewModel.watermarkCustomParams.rotationAngle = Int(round(angle * 360))
        }
    }
    
    private var customWatermarkDensityLevelBinding: Binding<Double> {
        Binding<Double> {
            Double(viewModel.watermarkCustomParams.densityLevel?.rawValue ?? ImageProcessor.DensityLevel.medium.rawValue)
        } set: { level in
            viewModel.watermarkCustomParams.densityLevel = ImageProcessor.DensityLevel(rawValue: Int(level))
        }
    }
    
    private let defaultSpacing: CGFloat = 16
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ScrollView {
                    VStack(alignment: .leading) {
                        HStack(alignment: .bottom, spacing: defaultSpacing) {
                            let childWidth: CGFloat = geometry.size.width / 2 - 1.5 * defaultSpacing
                            
                            Image(uiImage: selectedImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .background(Color(.sRGB, red: 0.3, green: 0.3, blue: 0.3, opacity: 1))
                                .frame(width: childWidth, alignment: .center)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .clipped(antialiased: true)
                            VStack {
                                buildButton("Nofotografēt", width: childWidth) {
                                    viewModel.takePicture()
                                }
                                buildButton("Importēt", width: childWidth) {
                                    viewModel.importPicture()
                                }
                            }
                        }
                        
                        Text("Ūdenszīme")
                            .padding([.top, .bottom], 8)
                            .font(.system(.subheadline))
                        
                        HStack {
                            Spacer()
                            Text("Teksts")
                            Toggle("", isOn: uiModeSwitchBinding)
                                .labelsHidden()
                            Text("Attēls")
                            Spacer()
                        }
                        
                        if viewModel.controlsType == .textWatermark {
                            textWatermarkControls
                        } else {
                            buildCustomWatermarkControls(geometry)
                        }
                        
                        Spacer()
                        
                        HStack {
                            Spacer()
                            buildButton("Iesniegt") {
                                viewModel.processImage()
                            }
                            Spacer()
                        }
                        .padding()
                    }
                    .padding([.leading, .trailing, .bottom], defaultSpacing)
                }
            }
            .navigationTitle("WatermarkBuilder")
            .sheet(isPresented: isResultSheetPresentedBinding) {
                resultSheet
            }
        }
    }
    
    @ViewBuilder
    private var textWatermarkControls: some View {
        TextField("Teksts", text: $viewModel.watermarkTextParams.text)
            .font(.system(size: 16, weight: .regular, design: .rounded))
            .padding(EdgeInsets(top: 12, leading: 8, bottom: 12, trailing: 8))
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke()
                    .stroke(.gray.opacity(0.3))
            )
            .padding(.horizontal, 1)
            .padding(.top, 16)
        
        Button {
            isFontFamilySheetPresented.toggle()
        } label: {
            HStack {
                Text(viewModel.watermarkTextParams.fontFamily ?? "Fontu saime")
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .padding(EdgeInsets(top: 12, leading: 8, bottom: 12, trailing: 8))
                Spacer()
            }
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke()
                    .stroke(.gray.opacity(0.3))
            )
            .padding(.horizontal, 1)
            .padding(.top, defaultSpacing)
        }
        .sheet(isPresented: $isFontFamilySheetPresented) {
            fontFamilySheet
        }
        
        HStack {
            HStack(spacing: 0) {
                let bold                    = viewModel.watermarkTextParams.fontWeight   == .w700
                let italic                  = viewModel.watermarkTextParams.isFontItalic == true
                let underline               = viewModel.watermarkTextParams.fontDecorations?.contains(.underline) == true
                let lineThrough             = viewModel.watermarkTextParams.fontDecorations?.contains(.lineThrough) == true
                let activeBackgroundColor   = Color(UIColor.systemBlue)
                let inactiveBackgroundColor = Color(UIColor.systemGray5)
                let activeForegroundColor   = Color.white
                let inactiveForegroundColor = Color.black
                
                Button {
                    viewModel.watermarkTextParams.fontWeight = bold ? .w400 : .w700
                } label: {
                    ZStack {
                        Rectangle()
                            .foregroundColor(bold ? activeBackgroundColor : inactiveBackgroundColor)
                        Text("B")
                            .font(.system(size: 16, weight: .heavy, design: .default))
                            .foregroundColor(bold ? activeForegroundColor : inactiveForegroundColor)
                            .padding(.vertical, 11)
                            .padding(.horizontal, 16)
                    }
                }
                .buttonStyle(.plain)
                .clipShape(PartiallyRoundedRectangle(corners: [.topLeft, .bottomLeft], radius: 12))
                
                Button {
                    viewModel.watermarkTextParams.isFontItalic = !italic
                } label: {
                    ZStack {
                        Rectangle()
                            .foregroundColor(italic ? activeBackgroundColor : inactiveBackgroundColor)
                        Text("I")
                            .font(.system(size: 16, weight: .semibold, design: .default))
                            .foregroundColor(italic ? activeForegroundColor : inactiveForegroundColor)
                            .italic()
                    }
                }
                
                Button {
                    if let decorations = viewModel.watermarkTextParams.fontDecorations {
                        viewModel.watermarkTextParams.fontDecorations = underline ? decorations.subtracting(.underline) : [decorations, .underline]
                    } else {
                        viewModel.watermarkTextParams.fontDecorations = .underline
                    }
                } label: {
                    ZStack {
                        Rectangle()
                            .foregroundColor(underline ? activeBackgroundColor : inactiveBackgroundColor)
                        Text("U")
                            .font(.system(size: 16, weight: .semibold, design: .default))
                            .foregroundColor(underline ? activeForegroundColor : inactiveForegroundColor)
                            .underline()
                    }
                }
                
                Button {
                    if let decorations = viewModel.watermarkTextParams.fontDecorations {
                        viewModel.watermarkTextParams.fontDecorations = lineThrough ? decorations.subtracting(.lineThrough) : [decorations, .lineThrough]
                    } else {
                        viewModel.watermarkTextParams.fontDecorations = .lineThrough
                    }
                } label: {
                    ZStack {
                        Rectangle()
                            .foregroundColor(lineThrough ? activeBackgroundColor : inactiveBackgroundColor)
                        Text("ab")
                            .font(.system(size: 16, weight: .semibold, design: .default))
                            .foregroundColor(lineThrough ? activeForegroundColor : inactiveForegroundColor)
                            .strikethrough()
                            .padding(.horizontal, 16)
                    }
                }
                .clipShape(PartiallyRoundedRectangle(corners: [.topRight, .bottomRight], radius: 12))

                Button {
                    isFontSizeSheetPresented.toggle()
                } label: {
                    ZStack {
                        Rectangle()
                            .foregroundColor(inactiveBackgroundColor)
                        HStack(alignment: .center, spacing: 4) {
                            Text(String(viewModel.watermarkTextParams.fontSize ?? ViewModel.defaultFontSize))
                                .font(.system(size: 16, weight: .semibold, design: .default))
                                .foregroundColor(inactiveForegroundColor)
                            Image(systemName: "chevron.down")
                                .scaleEffect(0.8)
                                .foregroundColor(inactiveForegroundColor)
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.leading, 8)
                .sheet(isPresented: $isFontSizeSheetPresented) {
                    fontSizeSheet
                }
            }
        }
        .padding(.top, 16)
        
        buildOpacitySlider(caption     : "Necaurredzamība",
                           currentValue: viewModel.watermarkTextParams.opacity ?? 0,
                           binding     : opacityBinding)
        
        buildRotationAngleSlider(currentValue: viewModel.watermarkTextParams.rotationAngle ?? 0,
                                 binding     : rotationAngleBinding)
        
        buildDensityLevelSlider(currentValue: viewModel.watermarkTextParams.densityLevel ?? ImageProcessor.DensityLevel.medium,
                                binding     : densityLevelBinding)
        
        buildColorPicker(caption: "Krāsa", binding: colorBinding)
        
        buildOpacitySlider(caption     : "Ēnas necaurredzamība",
                           currentValue: viewModel.watermarkTextParams.shadowOpacity ?? 0,
                           binding     : shadowOpacityBinding)
        
        buildColorPicker(caption: "Ēnas krāsa", binding: shadowColorBinding)
        
        HStack {
            Text("Ēna")
                .font(.system(.caption))
            Spacer()
            buildShadowDoubleParameterTextField(caption: "dX", binding: shadowOffsetXBinding)
            buildShadowDoubleParameterTextField(caption: "dY", binding: shadowOffsetYBinding)
            buildShadowDoubleParameterTextField(caption: "B",  binding: shadowBlurRadiusBinding)
        }
    }
    
    @ViewBuilder
    private func buildCustomWatermarkControls(_ geometry: GeometryProxy) -> some View {
        VStack(alignment: .leading) {
            HStack(alignment: .bottom, spacing: defaultSpacing) {
                let imageWidth   = geometry.size.width * 0.4 - 1.5 * defaultSpacing
                let buttonsWidth = geometry.size.width * 0.6 - 1.5 * defaultSpacing

                Image(uiImage: watermarkImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .background(Color(.sRGB, red: 0.3, green: 0.3, blue: 0.3, opacity: 1))
                    .frame(width: imageWidth, alignment: .center)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .clipped(antialiased: true)

                VStack {
                    buildButton("Nofotografēt", width: buttonsWidth, padding: 8) {
                        viewModel.takePicture(true)
                    }
                    buildButton("Importēt", width: buttonsWidth, padding: 8) {
                        viewModel.importPicture(true)
                    }
                }
            }
            
            buildOpacitySlider(caption     : "Necaurredzamība",
                               currentValue: viewModel.watermarkCustomParams.opacity ?? 0,
                               binding     : customWatermarkOpacityBinding)
            
            buildRotationAngleSlider(currentValue: viewModel.watermarkCustomParams.rotationAngle ?? 0,
                                     binding     : customWatermarkRotationAngleBinding)
            
            buildDensityLevelSlider(currentValue: viewModel.watermarkCustomParams.densityLevel ?? ImageProcessor.DensityLevel.medium,
                                    binding     : customWatermarkDensityLevelBinding)
        }
    }
    
    private var resultSheet: some View {
        NavigationView {
            VStack(alignment: .center) {
                Spacer()
                if case .pending = viewModel.requestStatus {
                    ProgressView()
                        .scaleEffect(2)
                } else if case let .fail(error) = viewModel.requestStatus {
                    Text(error.message)
                } else if case let .success(data) = viewModel.requestStatus {
                    Image(uiImage: UIImage(data: data) ?? UIImage())
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .background(Color(.sRGB, red: 0.3, green: 0.3, blue: 0.3, opacity: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .clipped(antialiased: true)
                        .padding()
                    
                    buildButton("Eksportēt") {
                        viewModel.exportImage()
                    }
                    .padding(.top, 24)
                }
                Spacer()
            }
            .navigationTitle({ () -> String in
                switch viewModel.requestStatus {
                case .pending: return "Attēls tiek apstrādāts..."
                case .fail   : return "Notika kļūda"
                case .success: return "Veiksme!"
                default      : return ""
                }
            }())
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var fontFamilySheet: some View {
        NavigationView {
            VStack {
                List(ViewModel.supportedFontFamilies, id: \.self) { fontFamily in
                    Button {
                        viewModel.watermarkTextParams.fontFamily = fontFamily
                        isFontFamilySheetPresented.toggle()
                    } label: {
                        HStack {
                            Text(fontFamily)
                            if viewModel.watermarkTextParams.fontFamily == fontFamily {
                                Spacer()
                                Image(systemName: "checkmark")
                                    .renderingMode(.template)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Fontu saime")
            .toolbar {
                ToolbarItem {
                    Button("Atcelt") {
                        isFontFamilySheetPresented.toggle()
                    }
                }
            }
        }
    }
    
    private var fontSizeSheet: some View {
        NavigationView {
            VStack {
                List(ViewModel.fontSizes, id: \.self) { fontSize in
                    Button {
                        viewModel.watermarkTextParams.fontSize = fontSize
                        isFontSizeSheetPresented.toggle()
                    } label: {
                        let selectedFontSize = viewModel.watermarkTextParams.fontSize ?? ViewModel.defaultFontSize
                        
                        HStack {
                            Text(String(fontSize))
                            if selectedFontSize == fontSize {
                                Spacer()
                                Image(systemName: "checkmark")
                                    .renderingMode(.template)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Fontu izmērs")
            .toolbar {
                ToolbarItem {
                    Button("Atcelt") {
                        isFontSizeSheetPresented.toggle()
                    }
                }
            }
        }
    }
    
    private func buildButton(_ text: String, width: CGFloat? = nil, padding: CGFloat? = nil, action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            Text(text)
                .foregroundColor(.white)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .padding(.all, padding ?? 16)
                .background {
                    RoundedRectangle(cornerRadius: 12, style: .circular)
                        .foregroundColor(.blue)
                        .frame(width: width, alignment: .center)
                }
        }
        .frame(width: width, alignment: .center)
    }
    
    @ViewBuilder
    private func buildShadowDoubleParameterTextField(caption: String, binding: Binding<String>) -> some View {
        Text(caption)
            .font(.system(.caption2))
        TextField("", text: binding)
            .font(.system(size: 16, weight: .regular, design: .rounded))
            .keyboardType(.numberPad)
            .padding(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke()
                    .stroke(.gray.opacity(0.3))
            )
            .frame(width: 50, alignment: .center)
    }
    
    private func buildDensityLevelSlider(currentValue: ImageProcessor.DensityLevel, binding: Binding<Double>) -> some View {
        HStack {
            let valueRange = Double(ImageProcessor.DensityLevel.min.rawValue)...Double(ImageProcessor.DensityLevel.max.rawValue)
            
            Text("Blīvums")
                .font(.system(.caption))
            Slider.init(value: binding, in: valueRange, step: 1)
            Text(String(currentValue.rawValue))
                .font(.system(.caption2))
        }
    }
    
    private func buildRotationAngleSlider(currentValue: Int, binding: Binding<Double>) -> some View {
        HStack {
            Text("Pagriešanas leņķis")
                .font(.system(.caption))
            Slider(value: binding)
            Text(String(currentValue).appending("°"))
                .font(.system(.caption2))
        }
    }
    
    private func buildOpacitySlider(caption: String, currentValue: Double, binding: Binding<Double>) -> some View {
        HStack {
            Text(caption)
                .font(.system(.caption))
            Slider(value: binding)
            Text(String(Int(round(currentValue * 100))).appending("%"))
                .font(.system(.caption2))
        }
    }
    
    private func buildColorPicker(caption: String, binding: Binding<Color>) -> some View {
        ColorPicker(selection: binding, supportsOpacity: false) {
            Text(caption)
                .font(.system(.caption))
        }
    }
}

struct PartiallyRoundedRectangle : Shape {
    
    let corners: UIRectCorner
    let radius : CGFloat
    
    func path(in rect: CGRect) -> Path {
        Path(UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius)).cgPath)
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .previewInterfaceOrientation(.portrait)
    }
}

private extension String {
    
    init(_ color: Color) {
        let cgColor = color.cgColor ?? UIColor.black.cgColor
        
        if let components = cgColor.components {
            let red   = Int(components[0] * 0xFF) << 16
            let green = Int(components[1] * 0xFF) << 8
            let blue  = Int(components[2] * 0xFF)
            
            let colorInteger = red | green | blue
            
            self = String(colorInteger, radix: 16)
        } else {
            self = "000000"
        }
    }
}

private extension Color {
    
    init(_ colorString: String) {
        let colorInteger = Int(colorString, radix: 16) ?? 0
        let red          = Double((colorInteger >> 16) & 0xFF) / 0xFF
        let green        = Double((colorInteger >>  8) & 0xFF) / 0xFF
        let blue         = Double((colorInteger      ) & 0xFF) / 0xFF
        
        self = Color(.sRGB, red: red, green: green, blue: blue, opacity: 1)
    }
}
