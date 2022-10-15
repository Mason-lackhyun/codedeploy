const axios = require('axios');
const cheerio = require('cheerio');
const iconv = require('iconv-lite');

exports.getWeather = async() => {
    const target_url = "https://www.weather.go.kr/w/weather/forecast/short-term.do?stnId=109#";
    const response = await axios.get(target_url,{
        responseType: "arraybuffer"
    });
    if (response.status == 200) {
        const html = iconv.decode(response.data, 'EUC-KR').toString();
        const $ = cheerio.load(html);
        const locationDetail = "서울"
        const todayLowTemp = $("tr:nth-child(1) > td:nth-child(2)").text();
        const todayHighTemp = $("tr:nth-child(2) > td:nth-child(4)").text();
        const tomorrowLowTemp = $("tr:nth-child(1) > td:nth-child(5)").text();
        const tomorrowHighTemp = $("tr:nth-child(2) > td:nth-child(5)").text();
        const location = locationDetail.substring(0,2);
        return {
            location, 
            todayLowTemp, 
            todayHighTemp, 
            tomorrowLowTemp, 
            tomorrowHighTemp
        }
    } 
}
"#highcharts-tfz7b66-62 > svg > rect.highcharts-background"
exports.createMessage = (temp) => {
    var message
    if (temp < 5) {
        message = '날씨가 춥네요. 패딩과 두꺼운 코트가 좋겠어요. 목도리나 기모제품도 챙겨주세요!';
    } else if (temp < 10) {
        message = '코트나 가죽자켓, 니트 정도가 좋겠네요. 내복은 필수!';
    } else if (temp < 13) {
        message = '멋부리기 좋은 계절. 트렌치코트나 야상, 자켓은 어떨까요?';
    } else if (temp < 18) {
        message = '자켓이나 가디건은 어때요?';
    } else if (temp < 22) {
        message = '흰색 긴팔에 청바지는 어떨까요. 밤에는 추울 수 있으니 얇은 겉옷도!';
    } else if (temp < 26) {
        message = '반팔이나 얇은 셔츠, 반바지나 면바지 등 가벼운 옷차림이 어울리겠어요.';
    } else {
        message = '날이 뜨거워요. 민소매 혹은 가벼운 옷차림! 선크림도 발라주세요.';
    }
    return message
}

exports.formatMessage = (location, todayLowTemp, todayHighTemp, tomorrowLowTemp, tomorrowHighTemp, Message) => {
    const formattedMessage = {
        type: 'mrkdwn',
        attachments: [
            {
                color: "#FFFFFF",
                fields: [
                    {
                        title: `날씨봇 ON !!! 현재 기온과 옷차림을 알려드리겠습니다.`,
                        value:
`-\n
오늘 ${location}은 *최고 ${todayHighTemp}°, 최저 ${todayLowTemp}°* 였으며,\n
내일 ${location}은 *최고 ${tomorrowHighTemp}°, 최저 ${tomorrowLowTemp}°* 입니다.\n
${Message}`,
                        short:false
                    }
                ]
            }
        ]
    };
    return formattedMessage;
}
