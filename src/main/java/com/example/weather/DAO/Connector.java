package com.example.weather.DAO;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.sql.*;
import java.util.List;
import java.util.Properties;

public class Connector {
    static Properties prop = new Properties();

    static {
        try {
            prop.load(Connector.class.getClassLoader().getResourceAsStream("data.properties"));
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    private static final String hostName = prop.getProperty("data.hostName");
    private static final String dbName = prop.getProperty("data.dbName");
    private static final String username = prop.getProperty("data.username");
    private static final String password = prop.getProperty("data.password");

    private static String connectionURL = "jdbc:mysql://" + hostName + "/" + dbName;

    public static Connection getControlConnection() throws SQLException {
        //Tạo đối tượng Connection
        Connection conn = null;
        try {
            conn = DriverManager.getConnection(connectionURL, username, password);
            System.out.println("Kết nối control db thành công");
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return conn;
    }

    public static Connection getConnection(String hostName, String dbName, String username, String password) throws SQLException {

        //Tạo đối tượng Connection
        Connection conn = null;
        try {
            conn = DriverManager.getConnection("jdbc:mysql://" + hostName + "/" + dbName, username, password);
            System.out.println("Kết nối " + dbName + " db thành công");
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return conn;
    }


    public static void updateFlagDataLinks(Connection conn, String id, String flag) throws SQLException {
        String updateQuery = "UPDATE data_link SET flag = ? WHERE id = ?";

        try (PreparedStatement preparedStatement = conn.prepareStatement(updateQuery)) {
            // Thiết lập giá trị tham số cho câu lệnh UPDATE
            preparedStatement.setString(1, flag);
            preparedStatement.setString(2, id);

            // Thực hiện cập nhật
            int rowsAffected = preparedStatement.executeUpdate();

            if (rowsAffected > 0) {
                System.out.println("Cập nhật flag " + flag + " bảng data_link thành công.");
            } else {
                System.out.println("Không có dòng nào trong bảng data_link được cập nhật.");
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }

    }

    public static void updateFlagConfig(Connection conn, String id, String flag) throws SQLException {
        String updateQuery = "UPDATE configuration SET flag = ? WHERE id = ?";

        try (PreparedStatement preparedStatement = conn.prepareStatement(updateQuery)) {
            // Thiết lập giá trị tham số cho câu lệnh UPDATE
            preparedStatement.setString(1, flag);
            preparedStatement.setString(2, id);

            // Thực hiện cập nhật
            int rowsAffected = preparedStatement.executeUpdate();

            if (rowsAffected > 0) {
                System.out.println("Cập nhật flag " + flag + " bảng configuration thành công.");
            } else {
                System.out.println("Không có dòng nào trong bảng configuration được cập nhật.");
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }

    }

    public static void updateStatusConfig(Connection conn, String id, String status) throws SQLException {
        String updateQuery = "UPDATE configuration SET status = ? WHERE id = ?";

        try (PreparedStatement preparedStatement = conn.prepareStatement(updateQuery)) {
            // Thiết lập giá trị tham số cho câu lệnh UPDATE
            preparedStatement.setString(1, status);
            preparedStatement.setString(2, id);

            // Thực hiện cập nhật
            int rowsAffected = preparedStatement.executeUpdate();

            if (rowsAffected > 0) {
                System.out.println("Cập nhật trạng thái " + status + " bảng configuration thành công.");
            } else {
                System.out.println("Không có dòng nào trong bảng configuration được cập nhật.");
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }
    public static String readFileAsString(String filePath) throws Exception {
        String data = "";
        data = new String(Files.readAllBytes(Paths.get(filePath)));
        return data;
    }
    // Phương thức trả về đối tượng ResultSet
    public static ResultSet getResultSetWithConfigFlags(Connection configConnection, String flag, String status) throws Exception {
        // Đọc nội dung của tệp vào một chuỗi
        String selectQuery = readFileAsString("get_config.sql");
        // Chuẩn bị câu truy vấn
        PreparedStatement preparedStatement = configConnection.prepareStatement(selectQuery);
        preparedStatement.setString(1, flag);
        preparedStatement.setString(2, status);

        // Thực hiện truy vấn và trả về ResultSet
        return preparedStatement.executeQuery();
    }
    public static void writeLog(Connection conn, String activityType, String description, String configId, String status, String errorDetail) throws SQLException {
        String insertQuery = "INSERT INTO logs (activity_type, description, config_id, status, error_detail) VALUES (?, ?, ?, ?, ?)";

        try (PreparedStatement preparedStatement = conn.prepareStatement(insertQuery)) {
            preparedStatement.setString(1, activityType);
            preparedStatement.setString(2, description);
            preparedStatement.setString(3, configId);
            preparedStatement.setString(4, status);
            preparedStatement.setString(5, errorDetail);

            int rowsInserted = preparedStatement.executeUpdate();
            if (rowsInserted > 0) {
                System.out.println("Inserted log " + activityType + "" + status + " successfully");
            } else {
                System.out.println("Failed to insert log");
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }
}
